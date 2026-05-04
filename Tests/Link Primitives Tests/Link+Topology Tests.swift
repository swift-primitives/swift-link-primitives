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

import Link_Primitives_Test_Support
import Testing

// MARK: - Test Harness

/// Manages a pool of doubly-linked nodes for topology tests.
///
/// Allocates a fixed-capacity buffer of `Link<2>.Node<Int>`, provides
/// the `linksAt` closure required by topology operations, and cleans up
/// on deinit.
@safe
private final class Pool {
    typealias N = Link<2>.Node<Int>

    let base: UnsafeMutablePointer<N>
    let capacity: UInt

    var sentinel: Index<N> { Index(__unchecked: (), Ordinal(capacity)) }

    init(capacity: UInt) {
        self.capacity = capacity
        unsafe (self.base = .allocate(capacity: Int(capacity)))
    }

    deinit {
        unsafe base.deallocate()
    }

    func initializeNode(at rawIndex: UInt, element: Int) {
        let s = sentinel
        let links = InlineArray<2, Index<N>>(repeating: s)
        unsafe (base + Int(rawIndex)).initialize(to: Link<2>.Node(links: links, element: element))
    }

    func linksAt(_ index: Index<N>) -> UnsafeMutablePointer<InlineArray<2, Index<N>>> {
        unsafe Link<2>.linksPointer(in: base + Int(bitPattern: index.position.rawValue))
    }

    func element(at rawIndex: UInt) -> Int {
        unsafe (base + Int(rawIndex)).pointee.element
    }

    /// Collects all indices from head to tail into an array for assertion.
    func collect(_ header: Link<2>.Header<N>) -> [UInt] {
        var result: [UInt] = []
        unsafe Link<2>.forEach(header: header, { unsafe self.linksAt($0) }) { index in
            result.append(index.position.rawValue)
        }
        return result
    }

    func makeHeader() -> Link<2>.Header<N> {
        Link<2>.Header<N>(sentinel: sentinel)
    }
}

// MARK: - Suites

@Suite
struct `Link Topology Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}

// MARK: - Unit: Append

extension `Link Topology Tests`.Unit {

    @Test
    func `append single node`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })

        #expect(header.head == 0)
        #expect(header.tail == 0)
        #expect(header.count == 1)
    }

    @Test
    func `append two nodes`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        pool.initializeNode(at: 1, element: 20)
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })
        unsafe Link<2>.append(1, header: &header, { unsafe pool.linksAt($0) })

        #expect(header.head == 0)
        #expect(header.tail == 1)
        #expect(header.count == 2)
        #expect(pool.collect(header) == [0, 1])
    }

    @Test
    func `append three nodes preserves order`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i) * 10) }
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })
        unsafe Link<2>.append(1, header: &header, { unsafe pool.linksAt($0) })
        unsafe Link<2>.append(2, header: &header, { unsafe pool.linksAt($0) })

        #expect(pool.collect(header) == [0, 1, 2])
        #expect(header.count == 3)
    }
}

// MARK: - Unit: Prepend

extension `Link Topology Tests`.Unit {

    @Test
    func `prepend single node`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        unsafe Link<2>.prepend(0, header: &header, { unsafe pool.linksAt($0) })

        #expect(header.head == 0)
        #expect(header.tail == 0)
        #expect(header.count == 1)
    }

    @Test
    func `prepend reverses insertion order`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        unsafe Link<2>.prepend(0, header: &header, { unsafe pool.linksAt($0) })
        unsafe Link<2>.prepend(1, header: &header, { unsafe pool.linksAt($0) })
        unsafe Link<2>.prepend(2, header: &header, { unsafe pool.linksAt($0) })

        #expect(pool.collect(header) == [2, 1, 0])
        #expect(header.head == 2)
        #expect(header.tail == 0)
        #expect(header.count == 3)
    }
}

// MARK: - Unit: Unlink

extension `Link Topology Tests`.Unit {

    @Test
    func `unlink middle node`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })
        unsafe Link<2>.append(1, header: &header, { unsafe pool.linksAt($0) })
        unsafe Link<2>.append(2, header: &header, { unsafe pool.linksAt($0) })

        unsafe Link<2>.unlink(1, header: &header, { unsafe pool.linksAt($0) })

        #expect(pool.collect(header) == [0, 2])
        #expect(header.count == 2)
    }

    @Test
    func `unlink head node`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        for i: UInt in 0..<3 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        unsafe Link<2>.unlink(0, header: &header, { unsafe pool.linksAt($0) })

        #expect(header.head == 1)
        #expect(pool.collect(header) == [1, 2])
        #expect(header.count == 2)
    }

    @Test
    func `unlink tail node`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        for i: UInt in 0..<3 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        unsafe Link<2>.unlink(2, header: &header, { unsafe pool.linksAt($0) })

        #expect(header.tail == 1)
        #expect(pool.collect(header) == [0, 1])
        #expect(header.count == 2)
    }
}

// MARK: - Unit: Unlink First

extension `Link Topology Tests`.Unit {

    @Test
    func `unlinkFirst returns head index`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        for i: UInt in 0..<3 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        let slot = unsafe Link<2>.unlinkFirst(header: &header, { unsafe pool.linksAt($0) })

        #expect(slot == 0)
        #expect(header.head == 1)
        #expect(header.count == 2)
        #expect(pool.collect(header) == [1, 2])
    }

    @Test
    func `unlinkFirst from single-element list`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })

        let slot = unsafe Link<2>.unlinkFirst(header: &header, { unsafe pool.linksAt($0) })

        #expect(slot == 0)
        #expect(header.head == header.sentinel)
        #expect(header.tail == header.sentinel)
        #expect(header.count == 0)
    }
}

// MARK: - Unit: Unlink Last

extension `Link Topology Tests`.Unit {

    @Test
    func `unlinkLast returns tail index`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        for i: UInt in 0..<3 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        let slot = unsafe Link<2>.unlinkLast(header: &header, { unsafe pool.linksAt($0) })

        #expect(slot == 2)
        #expect(header.tail == 1)
        #expect(header.count == 2)
        #expect(pool.collect(header) == [0, 1])
    }

    @Test
    func `unlinkLast from single-element list`() {
        let pool = Pool(capacity: 4)
        pool.initializeNode(at: 0, element: 10)
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })

        let slot = unsafe Link<2>.unlinkLast(header: &header, { unsafe pool.linksAt($0) })

        #expect(slot == 0)
        #expect(header.head == header.sentinel)
        #expect(header.tail == header.sentinel)
        #expect(header.count == 0)
    }
}

// MARK: - Unit: Insert After

extension `Link Topology Tests`.Unit {

    @Test
    func `insert after head`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })
        unsafe Link<2>.append(2, header: &header, { unsafe pool.linksAt($0) })

        unsafe Link<2>.insert(1, after: 0, header: &header, { unsafe pool.linksAt($0) })

        #expect(pool.collect(header) == [0, 1, 2])
        #expect(header.count == 3)
    }

    @Test
    func `insert after tail updates tail`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<2 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })

        unsafe Link<2>.insert(1, after: 0, header: &header, { unsafe pool.linksAt($0) })

        #expect(header.tail == 1)
        #expect(pool.collect(header) == [0, 1])
        #expect(header.count == 2)
    }
}

// MARK: - Unit: For Each

extension `Link Topology Tests`.Unit {

    @Test
    func `forEach visits all nodes in order`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i) * 10) }
        var header = pool.makeHeader()

        for i: UInt in 0..<3 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        var elements: [Int] = []
        unsafe Link<2>.forEach(header: header, { unsafe pool.linksAt($0) }) { index in
            elements.append(pool.element(at: index.position.rawValue))
        }

        #expect(elements == [0, 10, 20])
    }

    @Test
    func `forEach on empty list does nothing`() {
        let pool = Pool(capacity: 4)
        let header = pool.makeHeader()

        var visited = false
        unsafe Link<2>.forEach(header: header, { unsafe pool.linksAt($0) }) { _ in
            visited = true
        }

        #expect(!visited)
    }
}

// MARK: - Edge Case

extension `Link Topology Tests`.`Edge Case` {

    @Test
    func `unlinkFirst from empty list returns nil`() {
        let pool = Pool(capacity: 4)
        var header = pool.makeHeader()

        let slot = unsafe Link<2>.unlinkFirst(header: &header, { unsafe pool.linksAt($0) })

        #expect(slot == nil)
        #expect(header.count == 0)
    }

    @Test
    func `unlinkLast from empty list returns nil`() {
        let pool = Pool(capacity: 4)
        var header = pool.makeHeader()

        let slot = unsafe Link<2>.unlinkLast(header: &header, { unsafe pool.linksAt($0) })

        #expect(slot == nil)
        #expect(header.count == 0)
    }

    @Test
    func `unlink all nodes leaves empty list`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<3 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        for i: UInt in 0..<3 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        _ = unsafe Link<2>.unlinkFirst(header: &header, { unsafe pool.linksAt($0) })
        _ = unsafe Link<2>.unlinkFirst(header: &header, { unsafe pool.linksAt($0) })
        _ = unsafe Link<2>.unlinkFirst(header: &header, { unsafe pool.linksAt($0) })

        #expect(header.head == header.sentinel)
        #expect(header.tail == header.sentinel)
        #expect(header.count == 0)
        #expect(pool.collect(header) == [])
    }

    @Test
    func `append after drain`() {
        let pool = Pool(capacity: 4)
        for i: UInt in 0..<2 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })
        _ = unsafe Link<2>.unlinkFirst(header: &header, { unsafe pool.linksAt($0) })

        // Re-initialize node 0 links to sentinel before re-appending
        pool.initializeNode(at: 0, element: 99)
        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })

        #expect(header.head == 0)
        #expect(header.tail == 0)
        #expect(header.count == 1)
    }
}

// MARK: - Integration

extension `Link Topology Tests`.Integration {

    @Test
    func `mixed append prepend insert produces correct order`() {
        let pool = Pool(capacity: 8)
        for i: UInt in 0..<5 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        // Build: [0]
        unsafe Link<2>.append(0, header: &header, { unsafe pool.linksAt($0) })
        // Build: [0, 1]
        unsafe Link<2>.append(1, header: &header, { unsafe pool.linksAt($0) })
        // Build: [2, 0, 1]
        unsafe Link<2>.prepend(2, header: &header, { unsafe pool.linksAt($0) })
        // Build: [2, 0, 3, 1] — insert 3 after 0
        unsafe Link<2>.insert(3, after: 0, header: &header, { unsafe pool.linksAt($0) })
        // Build: [4, 2, 0, 3, 1] — prepend 4
        unsafe Link<2>.prepend(4, header: &header, { unsafe pool.linksAt($0) })

        #expect(pool.collect(header) == [4, 2, 0, 3, 1])
        #expect(header.head == 4)
        #expect(header.tail == 1)
        #expect(header.count == 5)
    }

    @Test
    func `drain from front one by one`() {
        let pool = Pool(capacity: 8)
        for i: UInt in 0..<4 { pool.initializeNode(at: i, element: Int(i) * 10) }
        var header = pool.makeHeader()

        for i: UInt in 0..<4 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        var drained: [Int] = []
        while let slot = unsafe Link<2>.unlinkFirst(header: &header, { unsafe pool.linksAt($0) }) {
            drained.append(pool.element(at: slot.position.rawValue))
        }

        #expect(drained == [0, 10, 20, 30])
        #expect(header.count == 0)
    }

    @Test
    func `drain from back one by one`() {
        let pool = Pool(capacity: 8)
        for i: UInt in 0..<4 { pool.initializeNode(at: i, element: Int(i) * 10) }
        var header = pool.makeHeader()

        for i: UInt in 0..<4 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        var drained: [Int] = []
        while let slot = unsafe Link<2>.unlinkLast(header: &header, { unsafe pool.linksAt($0) }) {
            drained.append(pool.element(at: slot.position.rawValue))
        }

        #expect(drained == [30, 20, 10, 0])
        #expect(header.count == 0)
    }

    @Test
    func `unlink middle then append reuses slot`() {
        let pool = Pool(capacity: 8)
        for i: UInt in 0..<4 { pool.initializeNode(at: i, element: Int(i)) }
        var header = pool.makeHeader()

        for i: UInt in 0..<3 { unsafe Link<2>.append(Index(__unchecked: (), Ordinal(i)), header: &header, { unsafe pool.linksAt($0) }) }

        // Unlink node 1 from [0, 1, 2]
        unsafe Link<2>.unlink(1, header: &header, { unsafe pool.linksAt($0) })
        #expect(pool.collect(header) == [0, 2])

        // Re-initialize node 1 and append as node 3's slot
        pool.initializeNode(at: 3, element: 99)
        unsafe Link<2>.append(3, header: &header, { unsafe pool.linksAt($0) })
        #expect(pool.collect(header) == [0, 2, 3])
        #expect(header.count == 3)
    }
}
