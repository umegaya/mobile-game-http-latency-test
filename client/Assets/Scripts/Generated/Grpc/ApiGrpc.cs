// Generated by the protocol buffer compiler.  DO NOT EDIT!
// source: api.proto
#pragma warning disable 1591
#region Designer generated code

using System;
using System.Threading;
using System.Threading.Tasks;
using grpc = global::Grpc.Core;

namespace LatencyResearchGrpc {
  /// <summary>
  /// The greeting service definition.
  /// </summary>
  public static partial class Service
  {
    static readonly string __ServiceName = "latency_research_grpc.Service";

    static readonly grpc::Marshaller<global::LatencyResearchGrpc.MeasureRequest> __Marshaller_MeasureRequest = grpc::Marshallers.Create((arg) => global::Google.Protobuf.MessageExtensions.ToByteArray(arg), global::LatencyResearchGrpc.MeasureRequest.Parser.ParseFrom);
    static readonly grpc::Marshaller<global::LatencyResearchGrpc.MeasureReply> __Marshaller_MeasureReply = grpc::Marshallers.Create((arg) => global::Google.Protobuf.MessageExtensions.ToByteArray(arg), global::LatencyResearchGrpc.MeasureReply.Parser.ParseFrom);
    static readonly grpc::Marshaller<global::LatencyResearchGrpc.HealthRequest> __Marshaller_HealthRequest = grpc::Marshallers.Create((arg) => global::Google.Protobuf.MessageExtensions.ToByteArray(arg), global::LatencyResearchGrpc.HealthRequest.Parser.ParseFrom);
    static readonly grpc::Marshaller<global::LatencyResearchGrpc.HealthReply> __Marshaller_HealthReply = grpc::Marshallers.Create((arg) => global::Google.Protobuf.MessageExtensions.ToByteArray(arg), global::LatencyResearchGrpc.HealthReply.Parser.ParseFrom);

    static readonly grpc::Method<global::LatencyResearchGrpc.MeasureRequest, global::LatencyResearchGrpc.MeasureReply> __Method_Measure = new grpc::Method<global::LatencyResearchGrpc.MeasureRequest, global::LatencyResearchGrpc.MeasureReply>(
        grpc::MethodType.Unary,
        __ServiceName,
        "Measure",
        __Marshaller_MeasureRequest,
        __Marshaller_MeasureReply);

    static readonly grpc::Method<global::LatencyResearchGrpc.HealthRequest, global::LatencyResearchGrpc.HealthReply> __Method_Health = new grpc::Method<global::LatencyResearchGrpc.HealthRequest, global::LatencyResearchGrpc.HealthReply>(
        grpc::MethodType.Unary,
        __ServiceName,
        "Health",
        __Marshaller_HealthRequest,
        __Marshaller_HealthReply);

    /// <summary>Service descriptor</summary>
    public static global::Google.Protobuf.Reflection.ServiceDescriptor Descriptor
    {
      get { return global::LatencyResearchGrpc.ApiReflection.Descriptor.Services[0]; }
    }

    /// <summary>Base class for server-side implementations of Service</summary>
    public abstract partial class ServiceBase
    {
      /// <summary>
      /// Sends a greeting
      /// </summary>
      /// <param name="request">The request received from the client.</param>
      /// <param name="context">The context of the server-side call handler being invoked.</param>
      /// <returns>The response to send back to the client (wrapped by a task).</returns>
      public virtual global::System.Threading.Tasks.Task<global::LatencyResearchGrpc.MeasureReply> Measure(global::LatencyResearchGrpc.MeasureRequest request, grpc::ServerCallContext context)
      {
        throw new grpc::RpcException(new grpc::Status(grpc::StatusCode.Unimplemented, ""));
      }

      public virtual global::System.Threading.Tasks.Task<global::LatencyResearchGrpc.HealthReply> Health(global::LatencyResearchGrpc.HealthRequest request, grpc::ServerCallContext context)
      {
        throw new grpc::RpcException(new grpc::Status(grpc::StatusCode.Unimplemented, ""));
      }

    }

    /// <summary>Client for Service</summary>
    public partial class ServiceClient : grpc::ClientBase<ServiceClient>
    {
      /// <summary>Creates a new client for Service</summary>
      /// <param name="channel">The channel to use to make remote calls.</param>
      public ServiceClient(grpc::Channel channel) : base(channel)
      {
      }
      /// <summary>Creates a new client for Service that uses a custom <c>CallInvoker</c>.</summary>
      /// <param name="callInvoker">The callInvoker to use to make remote calls.</param>
      public ServiceClient(grpc::CallInvoker callInvoker) : base(callInvoker)
      {
      }
      /// <summary>Protected parameterless constructor to allow creation of test doubles.</summary>
      protected ServiceClient() : base()
      {
      }
      /// <summary>Protected constructor to allow creation of configured clients.</summary>
      /// <param name="configuration">The client configuration.</param>
      protected ServiceClient(ClientBaseConfiguration configuration) : base(configuration)
      {
      }

      /// <summary>
      /// Sends a greeting
      /// </summary>
      /// <param name="request">The request to send to the server.</param>
      /// <param name="headers">The initial metadata to send with the call. This parameter is optional.</param>
      /// <param name="deadline">An optional deadline for the call. The call will be cancelled if deadline is hit.</param>
      /// <param name="cancellationToken">An optional token for canceling the call.</param>
      /// <returns>The response received from the server.</returns>
      public virtual global::LatencyResearchGrpc.MeasureReply Measure(global::LatencyResearchGrpc.MeasureRequest request, grpc::Metadata headers = null, DateTime? deadline = null, CancellationToken cancellationToken = default(CancellationToken))
      {
        return Measure(request, new grpc::CallOptions(headers, deadline, cancellationToken));
      }
      /// <summary>
      /// Sends a greeting
      /// </summary>
      /// <param name="request">The request to send to the server.</param>
      /// <param name="options">The options for the call.</param>
      /// <returns>The response received from the server.</returns>
      public virtual global::LatencyResearchGrpc.MeasureReply Measure(global::LatencyResearchGrpc.MeasureRequest request, grpc::CallOptions options)
      {
        return CallInvoker.BlockingUnaryCall(__Method_Measure, null, options, request);
      }
      /// <summary>
      /// Sends a greeting
      /// </summary>
      /// <param name="request">The request to send to the server.</param>
      /// <param name="headers">The initial metadata to send with the call. This parameter is optional.</param>
      /// <param name="deadline">An optional deadline for the call. The call will be cancelled if deadline is hit.</param>
      /// <param name="cancellationToken">An optional token for canceling the call.</param>
      /// <returns>The call object.</returns>
      public virtual grpc::AsyncUnaryCall<global::LatencyResearchGrpc.MeasureReply> MeasureAsync(global::LatencyResearchGrpc.MeasureRequest request, grpc::Metadata headers = null, DateTime? deadline = null, CancellationToken cancellationToken = default(CancellationToken))
      {
        return MeasureAsync(request, new grpc::CallOptions(headers, deadline, cancellationToken));
      }
      /// <summary>
      /// Sends a greeting
      /// </summary>
      /// <param name="request">The request to send to the server.</param>
      /// <param name="options">The options for the call.</param>
      /// <returns>The call object.</returns>
      public virtual grpc::AsyncUnaryCall<global::LatencyResearchGrpc.MeasureReply> MeasureAsync(global::LatencyResearchGrpc.MeasureRequest request, grpc::CallOptions options)
      {
        return CallInvoker.AsyncUnaryCall(__Method_Measure, null, options, request);
      }
      public virtual global::LatencyResearchGrpc.HealthReply Health(global::LatencyResearchGrpc.HealthRequest request, grpc::Metadata headers = null, DateTime? deadline = null, CancellationToken cancellationToken = default(CancellationToken))
      {
        return Health(request, new grpc::CallOptions(headers, deadline, cancellationToken));
      }
      public virtual global::LatencyResearchGrpc.HealthReply Health(global::LatencyResearchGrpc.HealthRequest request, grpc::CallOptions options)
      {
        return CallInvoker.BlockingUnaryCall(__Method_Health, null, options, request);
      }
      public virtual grpc::AsyncUnaryCall<global::LatencyResearchGrpc.HealthReply> HealthAsync(global::LatencyResearchGrpc.HealthRequest request, grpc::Metadata headers = null, DateTime? deadline = null, CancellationToken cancellationToken = default(CancellationToken))
      {
        return HealthAsync(request, new grpc::CallOptions(headers, deadline, cancellationToken));
      }
      public virtual grpc::AsyncUnaryCall<global::LatencyResearchGrpc.HealthReply> HealthAsync(global::LatencyResearchGrpc.HealthRequest request, grpc::CallOptions options)
      {
        return CallInvoker.AsyncUnaryCall(__Method_Health, null, options, request);
      }
      /// <summary>Creates a new instance of client from given <c>ClientBaseConfiguration</c>.</summary>
      protected override ServiceClient NewInstance(ClientBaseConfiguration configuration)
      {
        return new ServiceClient(configuration);
      }
    }

    /// <summary>Creates service definition that can be registered with a server</summary>
    /// <param name="serviceImpl">An object implementing the server-side handling logic.</param>
    public static grpc::ServerServiceDefinition BindService(ServiceBase serviceImpl)
    {
      return grpc::ServerServiceDefinition.CreateBuilder()
          .AddMethod(__Method_Measure, serviceImpl.Measure)
          .AddMethod(__Method_Health, serviceImpl.Health).Build();
    }

  }
}
#endregion