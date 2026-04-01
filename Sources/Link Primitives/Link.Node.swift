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

import Vector_Primitives
import Index_Primitives

extension Link {

    /// A linked list node containing N links and an element.
    ///
    /// Nodes are stored in pool or arena slots. Links are
    /// `Index<Node>` values pointing to other slots in the same pool.
    /// Convention: `links[0]` = next, `links[1]` = prev (when N >= 2).
    /// The pool's sentinel marks end-of-list.
    ///
    /// ## Links-First Layout
    ///
    /// Links are the first field so that `Link.linksPointer(in:)` can
    /// return the node pointer directly as a links pointer (offset 0).
    /// This enables Element-free topology operations — the `linksAt`
    /// closure needs no offset computation.
    ///
    /// `@frozen` because cross-module partial consumption of ~Copyable
    /// types requires known layout.
    @frozen
    public struct Node<Element: ~Copyable>: ~Copyable {
        /// Links to other nodes. `links[0]` = next, `links[1]` = prev (N >= 2).
        public var links: InlineArray<N, Index<Node>>

        /// The element value stored in this node.
        public var element: Element

        /// Creates a node with the given links and element.
        @inlinable
        public init(links: InlineArray<N, Index<Node>>, element: consuming Element) {
            self.links = links
            self.element = element
        }
    }
}

// MARK: - Links Pointer

extension Link {

    /// Returns a mutable pointer to the links array within the given node.
    ///
    /// Because `Node` is `@frozen` with `links` as the first field,
    /// the node pointer IS the links pointer at offset 0.
    /// This is zero-cost — no offset computation needed.
    ///
    /// - Parameter nodePointer: A mutable pointer to a node in the pool.
    /// - Returns: A mutable pointer to the node's links array.
    @inlinable @unsafe
    public static func linksPointer<Element: ~Copyable>(
        in nodePointer: UnsafeMutablePointer<Node<Element>>
    ) -> UnsafeMutablePointer<InlineArray<N, Index<Node<Element>>>> {
        unsafe UnsafeMutableRawPointer(nodePointer)
            .assumingMemoryBound(to: InlineArray<N, Index<Node<Element>>>.self)
    }
}

// MARK: - Conditional Conformances

extension Link.Node: Copyable where Element: Copyable {}
extension Link.Node: Sendable where Element: Sendable {}
