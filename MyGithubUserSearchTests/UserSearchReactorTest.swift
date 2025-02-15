//
//  UserSearchReactorTest.swift
//  MyGithubUserSearchTests
//
//  Created by tskim on 14/08/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import Foundation
import XCTest
import Cuckoo
import RxExpect
@testable import MyGithubUserSearch

class UserSearchReactorTest: XCTestCase {


    var reactor: UserSearchReactor!
    var api: MockNetworkRequest!

    override func setUp() {
        super.setUp()
        api = MockNetworkRequest()
        api.setUserItems()
        reactor = UserSearchReactor(api: api)
    }

    func testIfEmptyKeyword() {
        // 빈 텍스트를 호출하면 isLoading 상태가 변경되지 않아야 함
        let rxExpect = RxExpect()
        rxExpect.retain(reactor)
        rxExpect.input(reactor.action, [
                .next(0, .updateQuery(""))
            ])
        rxExpect.assert(reactor.state.map { $0.isLoading }.filterNil().distinctUntilChanged()) { events in
            XCTAssertEqual(events, [
                .next(0, false)
                ])
        }
    }
    func testIncreaseNextPage() {
        // 호출하면 다음 페이지가 2로 증가하는지 검증
        let rxExpect = RxExpect()
        rxExpect.retain(reactor)

        rxExpect.input(reactor.action, [
                .next(0, .updateQuery("a"))
            ])
        rxExpect.assert(reactor.state.map { $0.nextPage }.filterNil()) { events in
            XCTAssertEqual(events, [
                    .next(0, 2)
                ])
        }
    }
    func testSetStateQuery() {
        // query state가 정상적으로 변경되는지 검증
        let rxExpect = RxExpect()
        rxExpect.retain(reactor)

        rxExpect.input(reactor.action, [
                .next(0, .updateQuery("a"))
            ])
        rxExpect.assert(reactor.state.map { $0.query }.filterNil().distinctUntilChanged()) { events in
            XCTAssertEqual(events, [
                    .next(0, "a")
                ])
        }
    }
    func testUserItemPaging() {
        // 페이징 동작이 잘 동작하는 지 검증
        let expect = [
            [Fixture.UserItems.sampleUserItems.shuffled().first!],
            [Fixture.UserItems.sampleUserItems.shuffled().first!],
            [Fixture.UserItems.sampleUserItems.shuffled().first!]
        ]
        reset(api)
        api.setUserItemsPaging(expect)

        let rxExpect = RxExpect()
        rxExpect.retain(reactor)

        rxExpect.input(reactor.action, [
                .next(0, .updateQuery("a")),
                .next(10, .loadNextPage),
                .next(20, .loadNextPage),
            ])

        // Reivew: [성능] NextPage를 2번 가지고 오면 총 7번의 연산이 들어갑니다.
        // 3번의 Action을 수행했기 때문에 3번만 Item을 가지고 올 수 있도록 전략이 필요합니다.
        // 배열의 크기가 커지면 치명적인 성능저하가 일어납니다.
        rxExpect.assert(reactor.state.map { $0.userItems }.filterEmpty()) { events in
            XCTAssertEqual(events.count, 7)
            XCTAssertEqual(events[0], .next(0, expect[0]))
            XCTAssertEqual(events[1], .next(10, expect[0]))
            XCTAssertEqual(events[2], .next(10, expect[0] + expect[1]))
            XCTAssertEqual(events[3], .next(10, expect[0] + expect[1]))
            XCTAssertEqual(events[4], .next(20, expect[0] + expect[1]))
            XCTAssertEqual(events[5], .next(20, expect[0] + expect[1] + expect[2]))
            XCTAssertEqual(events[6], .next(20, expect[0] + expect[1] + expect[2]))
        }
    }
}
