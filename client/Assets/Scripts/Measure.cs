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

        IEnumerator Exec() {
            var rest = new RestPing(domain, iaas);
            var grpc = new GrpcPing(domain, iaas);

            yield return rest.Start(5, pattern);
            Dump("rest", rest);
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
