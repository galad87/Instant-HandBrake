//
//  OutputRedirect.swift
//  InstantHandBrake
//
//  Created by Damiano Galassi on 12/03/16.
//  Copyright © 2016 HandBrake. All rights reserved.
//

import Foundation

public class OutputRedirect {

    /// Global reference to OutputRedirect object that manages redirects for stdout.
    public static let stdoutRedirect = OutputRedirect(stream: stdout)
    /// Global reference to OutputRedirect object that manages redirects for stderr.
    public static let stderrRedirect = OutputRedirect(stream: stderr)

    public class ListenerEntry {
        fileprivate let f: (String) -> Void

        fileprivate init(f: @escaping (String) -> Void) {
            self.f = f
        }
    }

    /// Set that contains all registered listeners for this output.
    private var entries = [ListenerEntry]()

    /// Output stream (@c stdout or @c stderr) redirected by this object.
    private let stream: UnsafeMutablePointer<FILE>

    /// Pointer to old write function for the stream.
    private var oldWriteFunc: (@convention(c) (UnsafeMutableRawPointer?, UnsafePointer<Int8>?, Int32) -> Int32)?

    private init(stream: UnsafeMutablePointer<FILE>) {
        self.stream = stream
    }

    /// Function that replaces stdout->_write and forwards stdout to g_stdoutRedirect.
    private static let stdoutwrite: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<Int8>?, Int32) -> Int32 = { inFD, buffer, size in
        guard let buffer = buffer else { return 0 }
        let data = Data(bytes: buffer, count: Int(size))
        stdoutRedirect.forwardOutput(data)
        return size
    }

    /// Function that replaces stderr->_write and forwards stdout to g_stdoutRedirect.
    private static let stderrwrite: @convention(c) (UnsafeMutableRawPointer?, UnsafePointer<Int8>?, Int32) -> Int32 = { inFD, buffer, size in
        guard let buffer = buffer else { return 0 }
        let data = Data(bytes: buffer, count: Int(size))
        stderrRedirect.forwardOutput(data)
        return size
    }

    ///  Called from stdoutwrite() and stderrwrite() to forward the output to listeners.
    private func forwardOutput(_ data: Data) {
        if let string = String(data: data, encoding: String.Encoding.utf8) {
            DispatchQueue.main.async {
                for entry in self.entries {
                    entry.f(string)
                }
            }
        }
    }

    /// Starts redirecting the stream by redirecting its output to function
    private func startRedirect() {
        if oldWriteFunc == nil {
            oldWriteFunc = stream.pointee._write
            stream.pointee._write = stream == stdout ? OutputRedirect.stdoutwrite : OutputRedirect.stderrwrite
        }
    }

    /// Stops redirecting of the stream by returning the stream's _write function to original.
    private func stopRedirect() {
        if oldWriteFunc != nil {
            stream.pointee._write = oldWriteFunc
            oldWriteFunc = nil
        }
    }

    public func addListener(_ f: @escaping (String) -> Void) -> ListenerEntry {
        let entry = ListenerEntry(f: f)
        entries.append(entry)

        if entries.count > 0 {
            startRedirect()
        }

        return entry
    }

    public func removeListener(_ entry: ListenerEntry) {
        self.entries = self.entries.filter{ $0 !== entry }

        if entries.count == 0 {
            stopRedirect()
        }
    }
}
