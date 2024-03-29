package mhttp;

import java.security.InvalidParameterException;
import java.util.HashMap;
import java.util.regex.*;
import java.util.UUID;
import java.util.concurrent.*;
import java.lang.Exception;
import java.io.IOException;

// because no jar file reference. but suprisingly smart, 
// Unity Editor can correctly build this. 
import android.util.Log;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.HttpUrl;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Headers;
import okhttp3.RequestBody;
import okhttp3.Response;

public class Client {
    public class HttpTask implements Callback {
        public String uuid_;
        public Request request_;
        public Response response_ = null;
        public Exception error_ = null;

        public HttpTask(String uuid, Request r) {
            uuid_ = uuid;
            request_ = r;
        }
        @Override
        public void onFailure(Call call, IOException e) {
            error_ = e;
        }
        @Override
        public void onResponse(Call call, Response response) {
            response_ = response;

            Client.instance().finished_.add(uuid_);
        }
    }

    private static Client s_instance = null;
    private static Pattern s_sanitizePattern = Pattern.compile("^(https?://[^/]+)");
    private Client() {};

    public static Client instance() {
        if (s_instance == null) {
            s_instance = new Client();
        }
        return s_instance;
    }

    OkHttpClient client_ = new OkHttpClient();
    ConcurrentHashMap<String, HttpTask> tasks_ = new ConcurrentHashMap<String, HttpTask>();
    ConcurrentLinkedQueue<String> finished_ = new ConcurrentLinkedQueue<String>();

    public String execute(
        String uuid, 
        String url, String method, String[] headers, byte[] body
    ) {
        Request.Builder b = new Request.Builder().url(url);

        if (body != null) {
            b = b.method(method == null ? "POST" : method, RequestBody.create(null, body));
        } else {
            b = b.method("GET", null);
        }
        if (headers != null && headers.length > 0) {
            Headers.Builder hb = new Headers.Builder();
            for (int i = 0; i < headers.length; i += 2) {
                hb = hb.add(headers[i], headers[i + 1]);
            }
            b = b.headers(hb.build());
        }
        Request r = b.build();
        HttpTask t = new HttpTask(uuid, r);
        tasks_.put(uuid, t);

        client_.newCall(r).enqueue(t);

        return uuid;
    }

    public int code(String uuid) {
        HttpTask t = tasks_.get(uuid);
        if (t == null) {
            return -1;
        }
        if (t.error_ != null) {
            return -2;
        }
        if (t.response_ == null) {
            return -3;
        }
        return t.response_.code();
    }

    public String error(String uuid) {
        HttpTask t = tasks_.get(uuid);
        if (t == null) {
            return "task not found for : " + uuid;
        }
        if (t.error_ == null) {
            return null;
        }
        return t.error_.getMessage() + "@" + t.error_.getStackTrace();
    }

    public byte[] body(String uuid) {
        HttpTask t = tasks_.get(uuid);
        if (t == null || t.response_ == null) {
            return null;
        }
        try {
            return t.response_.body().bytes();
        } catch (IOException e) {
            return null;
        }
    }

    public String header(String uuid, String key) {
        HttpTask t = tasks_.get(uuid);
        if (t == null) {
            return null;
        }
        return t.response_.headers(key).get(0);
    }

    public void endResponse(String uuid) {
        tasks_.remove(uuid);
    }

    public String popFinished() {
        return finished_.poll();
    }
}
