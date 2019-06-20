using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace LatencyResearch {
    public class Measure : MonoBehaviour {
        public string domain;
        public string iaas;
        public PingRunner.Pattern pattern;

        void Start() {
            // StartCoroutine(Exec());
            StartCoroutine(ExecDownloadAndApiCall());
        }

        void Update() {
            Mhttp.Client.Update();
        }

        IEnumerator Exec() {
            var unity = new UnityPing(domain, iaas);
            var grpc = new GrpcPing(domain, iaas);
            var mhttp = new MhttpPing(domain, iaas);

            yield return unity.Start(5, pattern);
            Dump("unity", unity);
            yield return mhttp.Start(5, pattern);
            Dump("mhttp", mhttp);
            yield return grpc.Start(5, pattern);
            Dump("grpc", grpc);

            System.GC.Collect();
        }

        IEnumerator ExecDownloadAndApiCall() {
            var downloadFiles = new string [] {
                "capitol-2212102_1280.jpg",
                "jordan-1846284_1280.jpg",
                "sunset-4274662_1280.jpg",
                "hanoi-4176310_1280.jpg",
                "mirror-house-4278611_1280.jpg"
            };
            var unity = new UnityPing(domain, iaas);
            var mhttp = new MhttpPing(domain, iaas);

            yield return mhttp.StartDownload(downloadFiles, pattern);
            Dump("mhttp DL", mhttp);
            yield return unity.StartDownload(downloadFiles, pattern);
            Dump("unity DL", unity);

            var grpc = new GrpcPing(domain, iaas);
            var mhttp2 = new MhttpPing(domain, iaas);
            
            yield return mhttp2.Start(5, pattern);
            Dump("mhttp API", mhttp2);
            yield return grpc.Start(5, pattern);
            Dump("grpc API", grpc);

            System.GC.Collect();
        }

        void Dump(string header, PingRunner ping) {
            Debug.Log("---------- " + header + " ---------- takes " + ping.elapsed_time_ + " ms");
            string result = ping.results_[0].ToString();
            for (int i = 1; i < ping.results_.Length; i++) {
                result += ("|" + ping.results_[i]);
            }
            Debug.Log(result);
        }
    }
}
