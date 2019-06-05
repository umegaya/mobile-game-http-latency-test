using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;
using Grpc.Core;

using MeasureTask = Grpc.Core.AsyncUnaryCall<global::LatencyResearchGrpc.MeasureReply>;

namespace LatencyResearch {
class PingRunner {
    public long[] results_;
    public PingRunner() {
    }

    public IEnumerator Start(int n_attempt, bool parallel) {
        results_ = new long[n_attempt];
        return Exec(n_attempt, parallel);
    }
    public virtual IEnumerator Exec(int n_attempt, bool parallel) {
        yield return null;
    }
}
class RestPing : PingRunner {
    string url_;

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

    public override IEnumerator Exec(int n_attempt, bool parallel) {
        if (parallel) {
            var start_ts_list = new long[n_attempt];
            var wwws = new UnityWebRequest[n_attempt];
            for (int i = 0; i < n_attempt; i++) {
                start_ts_list[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                wwws[i] = CreateRequest(start_ts_list[i]);
            }
            int n_finish = 0;
            while (n_attempt > n_finish) {
                for (int i = 0; i < n_attempt; i++) {
                    if (wwws[i] != null && wwws[i].isDone) {
                        if (wwws[i].isNetworkError || wwws[i].isHttpError) {
                            Debug.Log(wwws[i].error);
                            results_[i] = -1;
                        } else {
                            results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts_list[i];
                        }
                        n_finish++;
                        wwws[i] = null;
                    }
                }
                yield return null;
            }
        } else {
            for (int i = 0; i < n_attempt; i++) {
                var start_ts = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                var www = CreateRequest(start_ts);
                yield return www.SendWebRequest();

                if (www.isNetworkError || www.isHttpError) {
                    Debug.Log(www.error);
                    results_[i] = -1;
                } else {
                    results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts;
                }
            }
        }

    }
}
class GrpcPing : PingRunner {
    Channel channel_;
    LatencyResearchGrpc.Service.ServiceClient client_;

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

    public override IEnumerator Exec(int n_attempt, bool parallel) {
        if (parallel) {
            var start_ts_list = new long[n_attempt];
            var tasks = new MeasureTask[n_attempt];
            for (int i = 0; i < n_attempt; i++) {
                start_ts_list[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                tasks[i] = Call(start_ts_list[i]);
            }
            int n_finish = 0;
            while (n_attempt > n_finish) {
                for (int i = 0; i < n_attempt; i++) {
                    if (tasks[i] != null && tasks[i].ResponseAsync.IsCompleted) {
                        results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts_list[i];
                        n_finish++;
                        tasks[i] = null;
                    }
                }
                yield return null;
            }
        } else {
            for (int i = 0; i < n_attempt; i++) {
                var start_ts = DateTimeOffset.Now.ToUnixTimeMilliseconds();
                var task = Call(start_ts);
                while (!task.ResponseAsync.IsCompleted) {
                    yield return null;
                }
                results_[i] = DateTimeOffset.Now.ToUnixTimeMilliseconds() - start_ts;
            }
        }
    }
}

}