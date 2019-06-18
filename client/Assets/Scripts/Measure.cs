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
            StartCoroutine(Exec());
        }

        void Update() {
            Mhttp.Client.Update();
        }

        IEnumerator Exec() {
            var rest = new RestPing(domain, iaas);
            var grpc = new GrpcPing(domain, iaas);
            var rest2 = new RestH2Ping(domain, iaas);

            yield return rest.Start(5, pattern);
            Dump("rest", rest);
            yield return rest2.Start(5, pattern);
            Dump("rest2", rest2);
            System.GC.Collect();
            yield return grpc.Start(5, pattern);
            Dump("grpc", grpc);
        }

        void Dump(string header, PingRunner ping) {
            Debug.Log("--------------- " + header + " ---------------");
            string result = ping.results_[0].ToString();
            for (int i = 1; i < ping.results_.Length; i++) {
                result += ("|" + ping.results_[i]);
            }
            Debug.Log(result);
        }
    }
}
