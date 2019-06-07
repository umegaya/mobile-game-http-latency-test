using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;
using Grpc.Core;

using MeasureTask = Grpc.Core.AsyncUnaryCall<global::LatencyResearchGrpc.MeasureReply>;

namespace LatencyResearch {
public class PingRunner {
    public enum Pattern {
        Sequencial,
        PausedSequencial,
        Parallel,
        PrewarmedParallel,
    }
    public long[] results_;
    public PingRunner() {
    }

    public IEnumerator Start(int n_attempt, Pattern p) {
        results_ = new long[n_attempt];
        PrepareSlots(n_attempt);
        switch (p) {
        case Pattern.Parallel: 
        case Pattern.PrewarmedParallel:
            var start_ts_list = new long[n_attempt];
            for (int i = 0; i < n_attempt; i++) {
                start_ts_list[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                InitSlot(i, start_ts_list[i]);
                if (p == Pattern.PrewarmedParallel && i == 0) {
                    while (!SlotFinished(i)) {
                        yield return null;
                    }
                    results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts_list[i];
                }
            }
            int n_start = p == Pattern.PrewarmedParallel ? 1 : 0;
            int n_finish = n_start;
            while (n_attempt > n_finish) {
                for (int i = n_start; i < n_attempt; i++) {
                    if (HasSlot(i) && SlotFinished(i)) {
                        string error = SlotError(i);
                        if (!string.IsNullOrEmpty(error)) {
                            Debug.Log(error);
                            results_[i] = -1;
                        } else {
                            results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts_list[i];
                        }
                        n_finish++;
                    }
                }
                yield return null;
            }
            break;
        case Pattern.Sequencial:
        case Pattern.PausedSequencial:
            for (int i = 0; i < n_attempt; i++) {
                var start_ts = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                InitSlot(i, start_ts);
                while (!SlotFinished(i)) {
                    yield return null;
                }

                string error = SlotError(i);
                if (!string.IsNullOrEmpty(error)) {
                    Debug.Log(error);
                    results_[i] = -1;
                } else {
                    results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts;
                }

                if (p == Pattern.PausedSequencial) {
                    yield return new WaitForSeconds(3.0f);
                }
            }
            break;
        }
    }
    public virtual void PrepareSlots(int size) {}
    public virtual void InitSlot(int slot_id, long start_ts) {}
    public virtual bool HasSlot(int slot_id) { return false; }
    public virtual bool SlotFinished(int slot_id) { return true; }
    public virtual string SlotError(int slot_id) { return null; }
}
class RestPing : PingRunner {
    string url_;
    UnityWebRequest[] slots_;

    public class PingProtocol {
        public long start_ts;
    }

    public RestPing(string domain, string iaas) : base() {
        url_ = string.Format("https://latency-research.rest.service.{0}/api/measure", domain);
    }

    UnityWebRequest CreateRequest(long start_ts) {
        var ping = new PingProtocol {
            start_ts = start_ts
        };
        var req = JsonUtility.ToJson(ping);
        byte[] postData = System.Text.Encoding.UTF8.GetBytes (req);
        var www = new UnityWebRequest(url_, "POST");
        www.uploadHandler = (UploadHandler)new UploadHandlerRaw(postData);
        www.downloadHandler = (DownloadHandler)new DownloadHandlerBuffer();
        www.SetRequestHeader("Content-Type", "application/json");
        return www;
    }

    public override void PrepareSlots(int size) {
        slots_ = new UnityWebRequest[size];
    }
    public override void InitSlot(int slot_id, long start_ts) {
        slots_[slot_id] = CreateRequest(start_ts);
        slots_[slot_id].SendWebRequest();
    }
    public override bool HasSlot(int slot_id) { return slots_[slot_id] != null; }
    public override bool SlotFinished(int slot_id) { return slots_[slot_id].isDone; }
    public override string SlotError(int slot_id) { return slots_[slot_id].error; }

}
/* class RestH2Ping : PingRunner {
    HttpClient client_;
}*/
class GrpcPing : PingRunner {
    Channel channel_;
    LatencyResearchGrpc.Service.ServiceClient client_;
    MeasureTask[] slots_;

    public GrpcPing(string domain, string iaas) : base() {
        channel_ = new Channel(
            string.Format("latency-research.grpc.service.{0}:50051", domain),
            ChannelCredentials.Insecure
        );
        client_ = new LatencyResearchGrpc.Service.ServiceClient(channel_);
    }

    MeasureTask Call(long start_ts) {
        return client_.MeasureAsync(new LatencyResearchGrpc.MeasureRequest {
            StartTs = (ulong)start_ts
        });
    }

    public override void PrepareSlots(int size) {
        slots_ = new MeasureTask[size];
    }
    public override void InitSlot(int slot_id, long start_ts) {
        slots_[slot_id] = Call(start_ts);
    }
    public override bool HasSlot(int slot_id) { return slots_[slot_id] != null; }
    public override bool SlotFinished(int slot_id) { return slots_[slot_id].ResponseAsync.IsCompleted; }
    public override string SlotError(int slot_id) { return null; }
}

}