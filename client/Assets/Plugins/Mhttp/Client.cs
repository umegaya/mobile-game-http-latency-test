using System;
using System.Collections;
using System.Collections.Generic;

using UnityEngine;

namespace Mhttp {
#if UNITY_ANDROID
    public class Client {
        const int PROCESSING_PER_LOOP = 10;
        public class Response {
            string uuid_;
            string error_;
            Request request_;

            internal Response(string uuid, Request r) {
                uuid_ = uuid;
                request_ = r;
                error_ = null;
                isDone = false;
            }

            public void Done() {
                isDone = true;
                error_ = Client.client_.Call<string>("error", uuid_);
            }

            public Request request {
                get {
                    return request_;
                }
            }

            public int code {
                get {
                    return Client.client_.Call<int>("code", uuid_);
                }
            }
            public string error {
                get {
                    return error_;
                }
            }
            public byte[] body {
                get {
                    AndroidJavaObject obj = Client.client_.Call<AndroidJavaObject>("body", uuid_);
                    if (obj.GetRawObject() != System.IntPtr.Zero) {
                        return AndroidJNI.FromByteArray(obj.GetRawObject());
                    } else {
                        return null;
                    }
                }
            }
            public string header(string key) {
                return Client.client_.Call<string>("header", uuid_, key);
            }
            public bool isDone {
                get; set;
            }
        }
        public class Request {
            public string url = null;
            public byte[] body = null;
            public string method = null;
            public Action<Response> callback = null;
        }
        public class Config {
            public string name_;
            public AndroidJavaObject config_;
            public Config(string name, Dictionary<string, string> headers) {
                name_ = name;
                config_ = client_.Call<AndroidJavaObject>("newConfig", name);
                foreach (var kv in headers) {
                    config_ = config_.Call<AndroidJavaObject>("setHeader", kv.Key, kv.Value);
                }
            }
        }
        static AndroidJavaObject client_;
        static Dictionary<string, Response> respmap_ = new Dictionary<string, Response>();

        static Client() {
            AndroidJavaClass cls = new AndroidJavaClass("main.java.mhttp.Client");
            client_ = cls.CallStatic<AndroidJavaObject>("instance");
        }

        public Config NewConfig(string name, Dictionary<string, string> headers) {
            return new Config(name, headers);
        }

        public Response Send(string configName, Request r) {
            var uuid = System.Guid.NewGuid().ToString();
            var resp = new Response(uuid, r);
            //var intptr = r.body != null ? AndroidJNI.ToByteArray(r.body) : System.IntPtr.Zero;
            Client.respmap_[uuid] = resp;
            Client.client_.Call<string>("execute", uuid, configName, r.url, r.method, r.body);
            return resp;
        }

        static public void Update() {
            int n_process = 0;
            while (n_process < PROCESSING_PER_LOOP) {
                var finished = client_.Call<string>("popFinished");
                if (finished == null) {
                    break;
                }
                Response resp;
                if (respmap_.TryGetValue(finished, out resp)) { 
                    resp.Done();
                    if (resp.request.callback != null) {
                        resp.request.callback(resp);
                    }
                }
                client_.Call("endResponse", finished);
                respmap_.Remove(finished);
                n_process++;
            }
        }
    }
#elif UNITY_IOS
    public class Client {
    }
#else
    public class Client : UnityWebRequest {
    }
#endif
}
