using System;
using System.Collections;
using System.Collections.Generic;

using UnityEngine;

namespace Mhttp {
#if UNITY_IOS
    public partial class Client {
        const int PROCESSING_PER_LOOP = 10;
        public class ResponseImpl : Response, IDisposable {
            string uuid_;
            Request request_;

            internal Response(string uuid, Request r) {
                uuid_ = uuid;
                request_ = r;
                isDone = false;
            }

            ~Response() {
                Dispose();
            }

            public void Dispose() {
                if (uuid_ != null) {
                    // Debug.Log("dispose:" + uuid_);
                    Client.dispose_queue_.Enqueue(uuid_);
                    uuid_ = null;
                }
            }

            public void Done() {
                isDone = true;
            }

            // implements Response
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
                    return Client.client_.Call<string>("error", uuid_);
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
        static AndroidJavaObject client_;
        static Dictionary<string, Response> respmap_ = new Dictionary<string, Response>();
        static Queue<string> dispose_queue_ = new Queue<string>();

        static Client() {
            AndroidJavaClass cls = new AndroidJavaClass("main.java.mhttp.Client");
            client_ = cls.CallStatic<AndroidJavaObject>("instance");
        }

        static public Response Send(Request r) {
            return null;
        }

        static public void Update() {
        }
    }
    #endif
}