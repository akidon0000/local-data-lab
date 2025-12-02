//
//  SimpleObjectCD+CoreDataProperties.swift
//  localDB-sampleer
//
//  Created by Claude Code
//

import Foundation
import CoreData

extension SimpleObjectCD {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SimpleObjectCD> {
        return NSFetchRequest<SimpleObjectCD>(entityName: "SimpleObjectCD")
    }

    @NSManaged public var id: String
    @NSManaged public var name: String

}

extension SimpleObjectCD : Identifiable {

}
