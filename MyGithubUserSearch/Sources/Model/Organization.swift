//
//  Organization.swift
//  MyGithubUserSearch
//
//  Created by Jinwoo Kim on 07/05/2019.
//  Copyright © 2019 jinuman. All rights reserved.
//

import Foundation
import RxDataSources

struct Organization {
    var organizationItems: [OrganizationItem]
}

extension Organization: SectionModelType {
    var items: [OrganizationItem] {
        return self.organizationItems
    }
    
    init(original: Organization, items: [OrganizationItem]) {
        self = original
        self.organizationItems = items
    }
}

struct OrganizationItem: Decodable, Equatable {
    let avatarUrl: String
    
    enum CodingKeys: String, CodingKey {
        case avatarUrl = "avatar_url"
    }
}
