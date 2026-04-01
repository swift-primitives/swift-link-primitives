// ===----------------------------------------------------------------------===//
//
// This source file is part of the swift-primitives open source project
//
// Copyright (c) 2024-2026 Coen ten Thije Boonkkamp and the swift-primitives project authors
// Licensed under Apache License v2.0
//
// See LICENSE for license information
//
// ===----------------------------------------------------------------------===//

import Index_Primitives
import Vector_Primitives

// MARK: - Link Topology Operations

extension Link {

    // MARK: Append

    /// Links `index` as the new tail of the list. O(1).
    ///
    /// The node's links MUST be initialized to sentinel before calling.
    /// This method only manipulates prev/next indices and the header —
    /// it does not allocate, initialize, or touch element storage.
    ///
    /// - Parameters:
    ///   - index: The node to link as the new tail.
    ///   - header: The list's cursor state.
    ///   - linksAt: Closure providing mutable access to the links array at a given index.
    @inlinable
    @unsafe
    public static func append<Tag: ~Copyable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        _ linksAt: (Index<Tag>) -> UnsafeMutablePointer<InlineArray<N, Index<Tag>>>
    ) {
        let sentinel = header.sentinel

        if header.tail != sentinel {
            unsafe linksAt(header.tail).pointee[0] = index
            if N >= 2 {
                unsafe linksAt(index).pointee[1] = header.tail
            }
        } else {
            header.head = index
        }

        header.tail = index
        unsafe linksAt(index).pointee[0] = sentinel
        header.count += .one
    }

    // MARK: Prepend

    /// Links `index` as the new head of the list. O(1).
    ///
    /// The node's links MUST be initialized to sentinel before calling.
    @inlinable
    @unsafe
    public static func prepend<Tag: ~Copyable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        _ linksAt: (Index<Tag>) -> UnsafeMutablePointer<InlineArray<N, Index<Tag>>>
    ) {
        let sentinel = header.sentinel

        if header.head != sentinel {
            unsafe linksAt(index).pointee[0] = header.head
            if N >= 2 {
                unsafe linksAt(header.head).pointee[1] = index
            }
        } else {
            header.tail = index
            unsafe linksAt(index).pointee[0] = sentinel
        }

        if N >= 2 {
            unsafe linksAt(index).pointee[1] = sentinel
        }

        header.head = index
        header.count += .one
    }

    // MARK: Unlink

    /// Unlinks `index` from the list. O(1) for N >= 2.
    ///
    /// After unlinking, the node's link slots are set to sentinel.
    /// The caller is responsible for extracting the element and
    /// deallocating the node.
    ///
    /// - Precondition: N >= 2 (doubly-linked). Singly-linked arbitrary
    ///   removal requires O(n) traversal and is not supported.
    @inlinable
    @unsafe
    public static func unlink<Tag: ~Copyable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        _ linksAt: (Index<Tag>) -> UnsafeMutablePointer<InlineArray<N, Index<Tag>>>
    ) {
        let sentinel = header.sentinel
        let linksPtr = unsafe linksAt(index)
        let prevIndex = unsafe linksPtr.pointee[1]
        let nextIndex = unsafe linksPtr.pointee[0]

        if prevIndex != sentinel {
            unsafe linksAt(prevIndex).pointee[0] = nextIndex
        } else {
            header.head = nextIndex
        }

        if nextIndex != sentinel {
            unsafe linksAt(nextIndex).pointee[1] = prevIndex
        } else {
            header.tail = prevIndex
        }

        unsafe linksPtr.pointee[0] = sentinel
        unsafe linksPtr.pointee[1] = sentinel

        header.count = header.count.subtract.saturating(.one)
    }

    // MARK: Unlink First

    /// Unlinks the head node and returns its index. O(1).
    ///
    /// Returns `nil` if the list is empty.
    /// After unlinking, the node's link slots are set to sentinel.
    @inlinable
    @unsafe
    public static func unlinkFirst<Tag: ~Copyable>(
        header: inout Header<Tag>,
        _ linksAt: (Index<Tag>) -> UnsafeMutablePointer<InlineArray<N, Index<Tag>>>
    ) -> Index<Tag>? {
        let sentinel = header.sentinel
        guard header.head != sentinel else { return nil }

        let slot = header.head
        let nextSlot = unsafe linksAt(slot).pointee[0]

        header.head = nextSlot
        if nextSlot != sentinel {
            if N >= 2 {
                unsafe linksAt(nextSlot).pointee[1] = sentinel
            }
        } else {
            header.tail = sentinel
        }

        unsafe linksAt(slot).pointee[0] = sentinel
        if N >= 2 {
            unsafe linksAt(slot).pointee[1] = sentinel
        }

        header.count = header.count.subtract.saturating(.one)
        return slot
    }

    // MARK: Unlink Last

    /// Unlinks the tail node and returns its index.
    ///
    /// O(1) for N >= 2 (doubly-linked). O(n) for N == 1 (traverses from head).
    /// Returns `nil` if the list is empty.
    @inlinable
    @unsafe
    public static func unlinkLast<Tag: ~Copyable>(
        header: inout Header<Tag>,
        _ linksAt: (Index<Tag>) -> UnsafeMutablePointer<InlineArray<N, Index<Tag>>>
    ) -> Index<Tag>? {
        let sentinel = header.sentinel
        guard header.tail != sentinel else { return nil }

        let slot = header.tail

        if N >= 2 {
            let prevSlot = unsafe linksAt(slot).pointee[1]

            header.tail = prevSlot
            if prevSlot != sentinel {
                unsafe linksAt(prevSlot).pointee[0] = sentinel
            } else {
                header.head = sentinel
            }

            unsafe linksAt(slot).pointee[0] = sentinel
            unsafe linksAt(slot).pointee[1] = sentinel
        } else {
            // O(n) singly-linked: traverse from head to find predecessor.
            var prevSlot = sentinel
            if header.head != slot {
                var current = header.head
                while current != sentinel {
                    let nextSlot = unsafe linksAt(current).pointee[0]
                    if nextSlot == slot {
                        prevSlot = current
                        break
                    }
                    current = nextSlot
                }
            }

            header.tail = prevSlot
            if prevSlot != sentinel {
                unsafe linksAt(prevSlot).pointee[0] = sentinel
            } else {
                header.head = sentinel
            }

            unsafe linksAt(slot).pointee[0] = sentinel
        }

        header.count = header.count.subtract.saturating(.one)
        return slot
    }

    // MARK: Insert

    /// Links `index` immediately after `position` in the list. O(1).
    ///
    /// The node's links MUST be initialized to sentinel before calling.
    ///
    /// - Precondition: `position` is a valid node in this list.
    @inlinable
    @unsafe
    public static func insert<Tag: ~Copyable>(
        _ index: Index<Tag>,
        after position: Index<Tag>,
        header: inout Header<Tag>,
        _ linksAt: (Index<Tag>) -> UnsafeMutablePointer<InlineArray<N, Index<Tag>>>
    ) {
        let sentinel = header.sentinel
        let nextSlot = unsafe linksAt(position).pointee[0]

        // Link new node between position and its successor.
        unsafe linksAt(position).pointee[0] = index
        unsafe linksAt(index).pointee[0] = nextSlot

        if N >= 2 {
            unsafe linksAt(index).pointee[1] = position
            if nextSlot != sentinel {
                unsafe linksAt(nextSlot).pointee[1] = index
            }
        }

        if nextSlot == sentinel {
            header.tail = index
        }

        header.count += .one
    }

    // MARK: For Each

    /// Visits each node index from head to tail. O(n).
    ///
    /// The body receives the index of each node. The caller uses the
    /// index to access the element via their own storage.
    @inlinable
    @unsafe
    public static func forEach<Tag: ~Copyable>(
        header: Header<Tag>,
        _ linksAt: (Index<Tag>) -> UnsafeMutablePointer<InlineArray<N, Index<Tag>>>,
        _ body: (Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel
        var current = header.head
        while current != sentinel {
            let nextSlot = unsafe linksAt(current).pointee[0]
            body(current)
            current = nextSlot
        }
    }
}
