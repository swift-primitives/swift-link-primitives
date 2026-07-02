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

    /// Links `index` as the new tail of the list.
    ///
    /// O(1).
    ///
    /// The node's links MUST be initialized to sentinel before calling.
    /// This method only manipulates prev/next indices and the header —
    /// it does not allocate, initialize, or touch element storage.
    ///
    /// Link access is pointer-free: `getLink` reads a node's link slot and
    /// `setLink` writes one. A consumer backs them with its storage's typed
    /// subscript (e.g. `storage[index].links[slot]`), never a raw pointer.
    ///
    /// - Parameters:
    ///   - index: The node to link as the new tail.
    ///   - header: The list's cursor state.
    ///   - getLink: Reads the link at `(index, slot)`.
    ///   - setLink: Writes `value` to the link at `(index, slot)`.
    @inlinable
    public static func append<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel

        if header.tail != sentinel {
            setLink(header.tail, 0, index)
            if N >= 2 {
                setLink(index, 1, header.tail)
            }
        } else {
            header.head = index
        }

        header.tail = index
        setLink(index, 0, sentinel)
        header.count += .one
    }

    // MARK: Prepend

    /// Links `index` as the new head of the list.
    ///
    /// O(1).
    ///
    /// The node's links MUST be initialized to sentinel before calling.
    @inlinable
    public static func prepend<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel

        if header.head != sentinel {
            setLink(index, 0, header.head)
            if N >= 2 {
                setLink(header.head, 1, index)
            }
        } else {
            header.tail = index
            setLink(index, 0, sentinel)
        }

        if N >= 2 {
            setLink(index, 1, sentinel)
        }

        header.head = index
        header.count += .one
    }

    // MARK: Unlink

    /// Unlinks `index` from the list.
    ///
    /// O(1) for N >= 2.
    ///
    /// After unlinking, the node's link slots are set to sentinel.
    /// The caller is responsible for extracting the element and
    /// deallocating the node.
    ///
    /// - Precondition: N >= 2 (doubly-linked). Singly-linked arbitrary
    ///   removal requires O(n) traversal and is not supported.
    @inlinable
    public static func unlink<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel
        let prevIndex = getLink(index, 1)
        let nextIndex = getLink(index, 0)

        if prevIndex != sentinel {
            setLink(prevIndex, 0, nextIndex)
        } else {
            header.head = nextIndex
        }

        if nextIndex != sentinel {
            setLink(nextIndex, 1, prevIndex)
        } else {
            header.tail = prevIndex
        }

        setLink(index, 0, sentinel)
        setLink(index, 1, sentinel)

        header.count = header.count.subtract.saturating(.one)
    }

    // MARK: Unlink First

    /// Unlinks the head node and returns its index.
    ///
    /// O(1).
    ///
    /// Returns `nil` if the list is empty.
    /// After unlinking, the node's link slots are set to sentinel.
    @inlinable
    public static func unlinkFirst<Tag: ~Copyable & ~Escapable>(
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) -> Index<Tag>? {
        let sentinel = header.sentinel
        guard header.head != sentinel else { return nil }

        let slot = header.head
        let nextSlot = getLink(slot, 0)

        header.head = nextSlot
        if nextSlot != sentinel {
            if N >= 2 {
                setLink(nextSlot, 1, sentinel)
            }
        } else {
            header.tail = sentinel
        }

        setLink(slot, 0, sentinel)
        if N >= 2 {
            setLink(slot, 1, sentinel)
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
    public static func unlinkLast<Tag: ~Copyable & ~Escapable>(
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) -> Index<Tag>? {
        let sentinel = header.sentinel
        guard header.tail != sentinel else { return nil }

        let slot = header.tail

        if N >= 2 {
            let prevSlot = getLink(slot, 1)

            header.tail = prevSlot
            if prevSlot != sentinel {
                setLink(prevSlot, 0, sentinel)
            } else {
                header.head = sentinel
            }

            setLink(slot, 0, sentinel)
            setLink(slot, 1, sentinel)
        } else {
            // O(n) singly-linked: traverse from head to find predecessor.
            var prevSlot = sentinel
            if header.head != slot {
                var current = header.head
                while current != sentinel {
                    let nextSlot = getLink(current, 0)
                    if nextSlot == slot {
                        prevSlot = current
                        break
                    }
                    current = nextSlot
                }
            }

            header.tail = prevSlot
            if prevSlot != sentinel {
                setLink(prevSlot, 0, sentinel)
            } else {
                header.head = sentinel
            }

            setLink(slot, 0, sentinel)
        }

        header.count = header.count.subtract.saturating(.one)
        return slot
    }

    // MARK: Insert

    /// Links `index` immediately after `position` in the list.
    ///
    /// O(1).
    ///
    /// The node's links MUST be initialized to sentinel before calling.
    ///
    /// - Precondition: `position` is a valid node in this list.
    @inlinable
    public static func insert<Tag: ~Copyable & ~Escapable>(
        _ index: Index<Tag>,
        after position: Index<Tag>,
        header: inout Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        setLink: (Index<Tag>, Int, Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel
        let nextSlot = getLink(position, 0)

        // Link new node between position and its successor.
        setLink(position, 0, index)
        setLink(index, 0, nextSlot)

        if N >= 2 {
            setLink(index, 1, position)
            if nextSlot != sentinel {
                setLink(nextSlot, 1, index)
            }
        }

        if nextSlot == sentinel {
            header.tail = index
        }

        header.count += .one
    }

    // MARK: For Each

    /// Visits each node index from head to tail.
    ///
    /// O(n).
    ///
    /// The body receives the index of each node. The caller uses the
    /// index to access the element via their own storage.
    @inlinable
    public static func forEach<Tag: ~Copyable & ~Escapable>(
        header: Header<Tag>,
        getLink: (Index<Tag>, Int) -> Index<Tag>,
        _ body: (Index<Tag>) -> Void
    ) {
        let sentinel = header.sentinel
        var current = header.head
        while current != sentinel {
            let nextSlot = getLink(current, 0)
            body(current)
            current = nextSlot
        }
    }
}
