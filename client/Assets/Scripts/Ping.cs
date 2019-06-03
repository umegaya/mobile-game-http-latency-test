using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;

namespace LatencyResearch {
    public class Ping : MonoBehaviour {
        public string domain;
        public string iaas;
        public string protocol;
        void Awake() {

        }

        void Start() {
            StartCoroutine(MeasureLatency(new string[] { protocol, iaas }));
        }

        public class PingProtocol {
            public long start_ts;
        }

        IEnumerator MeasureLatency(string[] settings) {
            var url = "https://latency-research-" + 
                settings[0] + 
                ".service" + 
                (settings[1] == "aws" ? "" : ".gcp") + 
                "." + domain + "/measure";

            Debug.Log(url);

            for (int i = 0; i < 5; i++) {
                var ping = new PingProtocol {
                    start_ts = DateTimeOffset.Now.ToUnixTimeMilliseconds()
                };
                var req = JsonUtility.ToJson(ping);
                byte[] postData = System.Text.Encoding.UTF8.GetBytes (req);
                var www = new UnityWebRequest(url, "POST");
                www.uploadHandler = (UploadHandler)new UploadHandlerRaw(postData);
                www.downloadHandler = (DownloadHandler)new DownloadHandlerBuffer();
                www.SetRequestHeader("Content-Type", "application/json");
                yield return www.SendWebRequest();

                if (www.isNetworkError || www.isHttpError) {
                    Debug.Log(www.error);
                } else {
                    var respPing = JsonUtility.FromJson<PingProtocol>(www.downloadHandler.text);
                    if (ping.start_ts != respPing.start_ts) {
                        Debug.Log("invalid response:" + respPing.start_ts + "|" + www.downloadHandler.text + "|" + req);
                    }
                    Debug.Log("latency: " + (DateTimeOffset.Now.ToUnixTimeMilliseconds() - ping.start_ts) + " ms");
                }
            }
        }
    }
}
