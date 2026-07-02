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
    /// Links are the first field so that a links view sits at offset 0,
    /// independent of `Element`. Topology operations are element-free —
    /// they read and write link slots through the `getLink` / `setLink`
    /// accessors, never touching element storage.
    ///
    /// `@frozen` because cross-module partial consumption of ~Copyable
    /// types requires known layout.
    @frozen
    public struct Node<Element: ~Copyable>: ~Copyable {
        /// Links to other nodes.
        ///
        /// `links[0]` = next, `links[1]` = prev (N >= 2).
        public var links: InlineArray<N, Index<Node>>

        /// The element value stored in this node.
        public var element: Element

        /// Creates a node with the given links and element.
        @inlinable
        // swiftlint:disable:next prefer_self_in_static_references - reason: deliberate phantom-tag idiom — links ARE `Index<Node>` values (see type doc above); the tag names the concept, so `Self` would obscure what the index indexes
        public init(links: InlineArray<N, Index<Node>>, element: consuming Element) {
            self.links = links
            self.element = element
        }
    }
}

// MARK: - Conditional Conformances

extension Link.Node: Copyable where Element: Copyable {}
extension Link.Node: Sendable where Element: Sendable {}
