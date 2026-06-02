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

extension Link {

    /// Pure cursor state for a linked list.
    ///
    /// Tracks head, tail, count, and the sentinel value derived from
    /// the pool's capacity. Copyable and Sendable — just a few integers.
    ///
    /// Generic over a phantom `Tag` for index type safety. The tag is
    /// typically `Link<N>.Node<Element>`, but can be any type — the
    /// header never inspects or constrains the tag beyond phantom use.
    public struct Header<Tag: ~Copyable & ~Escapable>: Copyable, Sendable {
        /// Index of the first node. Sentinel = empty list.
        public var head: Index<Tag>

        /// Index of the last node. Sentinel = empty list.
        public var tail: Index<Tag>

        /// Number of elements in the list.
        public var count: Index<Tag>.Count

        /// Sentinel value (pool capacity as ordinal). Marks end-of-list.
        public let sentinel: Index<Tag>

        /// Creates a header for an empty list with the given sentinel.
        @inlinable
        public init(sentinel: Index<Tag>) {
            self.head = sentinel
            self.tail = sentinel
            self.count = .zero
            self.sentinel = sentinel
        }
    }
}
