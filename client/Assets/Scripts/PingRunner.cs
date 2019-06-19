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
    public class PingProtocol {
        public long start_ts;
    }
    public long[] results_;
    public PingRunner() {
    }

    public bool VerifyResponse(int slot_id, long start_ts) {
        var obj = SlotResponse(slot_id);
        long resp_start_ts;
        if (obj == null) {
            Debug.Log("obj == null");
            return false;
        }
        if (obj.GetType() == typeof(byte[])) {
            var data = System.Text.Encoding.UTF8.GetString(
                (byte[])obj
            );
            var resp = JsonUtility.FromJson<PingProtocol>(data);
            resp_start_ts = resp.start_ts;
        } else if (obj.GetType() == typeof(LatencyResearchGrpc.MeasureReply)) {
            var resp = (LatencyResearchGrpc.MeasureReply)obj;
            resp_start_ts = (long)resp.StartTs;
        } else {
            Debug.Log("invalid response type:" + obj.GetType().Name);
            return false;
        }
        if (resp_start_ts != start_ts) {
            return false;
        }
        return true;
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
                    string error = SlotError(i);
                    if (!string.IsNullOrEmpty(error)) {
                        results_[i] = -1;
                    } else if (!VerifyResponse(i, start_ts_list[i])) {
                        Debug.Log("response incorrect");
                        results_[i] = -1;
                    } else {
                        results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts_list[i];
                    }
                    FinSlot(i);
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
                        } else if (!VerifyResponse(i, start_ts_list[i])) {
                            Debug.Log("response incorrect");
                            results_[i] = -1;
                        } else {
                            results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts_list[i];
                        }
                        FinSlot(i);
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
                } else if (!VerifyResponse(i, start_ts)) {
                    Debug.Log("response incorrect");
                    results_[i] = -1;
                } else {
                    results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts;
                }
                FinSlot(i);

                if (p == Pattern.PausedSequencial) {
                    yield return new WaitForSeconds(3.0f);
                }
            }
            break;
        }
    }
    public virtual void PrepareSlots(int size) {}
    public virtual void InitSlot(int slot_id, long start_ts) {}
    public virtual void FinSlot(int slot_id) {}
    public virtual bool HasSlot(int slot_id) { return false; }
    public virtual bool SlotFinished(int slot_id) { return true; }
    public virtual string SlotError(int slot_id) { return null; }
    public virtual object SlotResponse(int slot_id) { return null; }
}
class RestPing : PingRunner {
    string url_;
    UnityWebRequest[] slots_;

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
    public override void FinSlot(int slot_id) { slots_[slot_id] = null; }
    public override object SlotResponse(int slot_id) { return slots_[slot_id].downloadHandler.data; }
}
class RestH2Ping : PingRunner {
    string url_;
    Mhttp.Client.Response[] slots_;

    public RestH2Ping(string domain, string iaas) {
        url_ = string.Format("https://latency-research.rest.service.{0}/api/measure", domain);
    }

    public override void PrepareSlots(int size) {
        slots_ = new Mhttp.Client.Response[size];
    }
    public override void InitSlot(int slot_id, long start_ts) {
        var ping = new PingProtocol {
            start_ts = start_ts
        };
        var req = JsonUtility.ToJson(ping);
        byte[] postData = System.Text.Encoding.UTF8.GetBytes (req);
        slots_[slot_id] = Mhttp.Client.Send(new Mhttp.Client.Request {
            url = url_,
            headers = new Dictionary<string, string> {
                { "Content-Type", "application/json" }
            },
            body = postData,
        });
    }
    public override bool HasSlot(int slot_id) { return slots_[slot_id] != null; }
    public override bool SlotFinished(int slot_id) { return slots_[slot_id].isDone; }
    public override string SlotError(int slot_id) { return slots_[slot_id].error; }
    public override void FinSlot(int slot_id) { slots_[slot_id] = null; }
    public override object SlotResponse(int slot_id) { return slots_[slot_id].data; }
}
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
    public override string SlotError(int slot_id) { 
        var ex = slots_[slot_id].ResponseAsync.Exception; 
        return ex != null ? ex.ToString() : null;
    }
    public override void FinSlot(int slot_id) { slots_[slot_id] = null; }
    public override object SlotResponse(int slot_id) { return slots_[slot_id].ResponseAsync.Result; }
}

}