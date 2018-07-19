//
//  TCPServer.swift
//  App
//
//  Created by fox on 2018/7/19.
//

import Foundation

import NIO

public typealias OnRead = (_ socket: Channel,_ data: NIOAny)-> Void
public class TCPServer {
    
    let host: String
    let port: Int
    let eventLoop: EventLoop
    public var onRead : OnRead?
    public var onWrite : OnRead?
    public var onError : (Error) -> Void = { print($0) }
    
    private let tcpThread = dispatch_queue_concurrent_t(label: "tcp");
    
    func bootstrap() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        let handler = EchoHandler()
        handler.onRead = onRead
        let bootstrap = ServerBootstrap(group: group)
            // Specify backlog and enable SO_REUSEADDR for the server itself
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            
            // Set the handlers that are appled to the accepted Channels
            .childChannelInitializer { channel in
                // Ensure we don't read faster then we can write by adding the BackPressureHandler into the pipeline.
                channel.pipeline.add(handler: BackPressureHandler()).then { v in
                    channel.pipeline.add(handler: handler)
                }
            }
            
            // Enable TCP_NODELAY and SO_REUSEADDR for the accepted Channels
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        defer {
            try! group.syncShutdownGracefully()
        }
        
        
        enum BindTo {
            case ip(host: String, port: Int)
            case unixDomainSocket(path: String)
        }
        
        let bindTarget: BindTo = .ip(host: self.host, port: self.port)
        
        let channel = try { () -> Channel in
            switch bindTarget {
            case .ip(let host, let port):
                return try bootstrap.bind(host: host, port: port).wait()
            case .unixDomainSocket(let path):
                return try bootstrap.bind(unixDomainSocketPath: path).wait()
            }
            }()
        
        print("Server started and listening on \(channel.localAddress!)")
        
        // This will never unblock as we don't close the ServerChannelc
        try channel.closeFuture.wait()
    }
    
    
    
    public init(host: String, port: Int ,eventLoop: EventLoop) {
        self.host = host
        self.port = port
        self.eventLoop = eventLoop
        
        
    }
    
    @discardableResult
    public func listen() -> EventLoopFuture<String> {
        let p : EventLoopPromise<String> = eventLoop.newPromise()
        tcpThread.async {
            do {
                try  self.bootstrap()
                p.succeed(result: "ok")
            } catch let err {
                p.fail(error: err)
            }
            
        }
        
        
        return p.futureResult
    }
    
    func write() throws {
        
    }
    
    private final class EchoHandler: ChannelInboundHandler {
        public typealias InboundIn = ByteBuffer
        public typealias OutboundOut = ByteBuffer
        var onRead : OnRead?
        var onWrite : OnRead?
        
        public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
            // As we are not really interested getting notified on success or failure we just pass nil as promise to
            // reduce allocations.
            self.onRead?(ctx.channel,data)
        }
        
        // Flush it out. This can make use of gathering writes if multiple buffers are pending
        public func channelReadComplete(ctx: ChannelHandlerContext) {
            
            // As we are not really interested getting notified on success or failure we just pass nil as promise to
            // reduce allocations.
            ctx.flush()
        }
        
        public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
            print("error: ", error)
            
            // As we are not really interested getting notified on success or failure we just pass nil as promise to
            // reduce allocations.
            ctx.close(promise: nil)
        }
    }
}

