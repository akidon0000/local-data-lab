//
//  ComplexIndexData.swift
//  LocalDataLab
//
//  Created by Akihiro Matsuyama on 2025/10/16.
//

import Foundation
import SwiftData

enum ComplexIndexDataError: Error {
    case dataNotFound
}

// MARK: - School

@Model final class ComplexIndexSchool {
    #Index<ComplexIndexSchool>([\.name])
    
    static func predicate(
        name: String
    ) -> Predicate<ComplexIndexSchool> {
        return #Predicate<ComplexIndexSchool> { school in
            school.name.starts(with: name)
        }
    }
    
    enum SchoolType: Codable, CaseIterable {
        case comprehensive
        case grammar
        case `private`
        case religious
    }
    
    @Attribute(.unique) var id: String
    var name: String
    var location: String
    var type: SchoolType
    // 親 -> 子 側は deleteRule のみ（inverse は子側で指定）
    @Relationship(deleteRule: .cascade) var students: [ComplexIndexStudent]
    
    init() throws {
        let name = HiraganaGenerator.makeRandomName(length: 10)
        guard let location = ComplexIndexDataFixtures.schoolLocations.randomElement(),
              let type = SchoolType.allCases.randomElement() else {
            throw ComplexIndexDataError.dataNotFound
        }
        self.id = UUID().uuidString
        self.name = name
        self.location = location
        self.type = type
        self.students = []
    }
    init(id: String = UUID().uuidString, name: String, location: String, type: SchoolType, students: [ComplexIndexStudent] = []) {
        self.id = id
        self.name = name
        self.location = location
        self.type = type
        self.students = students
    }
}

// MARK: - Student

@Model final class ComplexIndexStudent {
    @Attribute(.unique) var id: String
    var firstName: String
    var surname: String
    var age: Int
    // 子 -> 親 側で inverse を指定
    @Relationship(inverse: \ComplexIndexSchool.students) var school: ComplexIndexSchool?
    // 親 -> 子 側は deleteRule のみ（inverse は子側で指定）
    @Relationship(deleteRule: .cascade) var grades: [ComplexIndexGrade]
    
    var displayName: String { "\(firstName) \(surname)" }
    
    init(school: ComplexIndexSchool) throws {
        guard let firstName = ComplexIndexDataFixtures.firstNames.randomElement(),
              let surname = ComplexIndexDataFixtures.surnames.randomElement() else {
            throw ComplexIndexDataError.dataNotFound
        }
        self.id = UUID().uuidString
        self.firstName = firstName
        self.surname = surname
        self.age = Int.random(in: 11..<18)
        self.school = school
        self.grades = ComplexIndexGrade.randomGrades()
    }
    
    init(id: String = UUID().uuidString, firstName: String, surname: String, age: Int, grades: [ComplexIndexGrade] = [], school: ComplexIndexSchool? = nil) {
        self.id = id
        self.firstName = firstName
        self.surname = surname
        self.age = age
        self.school = school
        self.grades = grades
    }
}

// MARK: - Grade

@Model final class ComplexIndexGrade {
    enum Subject: String, CaseIterable {
        case maths
        case english
        case literature
        case physics
        case chemistry
        case biology
        case history
        case geography
        case french
        case german
        case music
        case art
        case physicalEducation
        case religiousStudies
    }
    
    enum Grade: String, CaseIterable {
        case aStar
        case a
        case b
        case c
        case d
        case e
        case f
        case u
    }
    
    enum ExamBoard: String, CaseIterable {
        case aqa
        case edexcel
        case ocr
    }
    
    @Attribute(.unique) var id: String
    // SwiftData のマクロや述語は enum を苦手とするため rawValue を保持
    var subject: String
    var grade: String
    var examBoard: String
    // 子 -> 親 側で inverse を指定
    @Relationship(inverse: \ComplexIndexStudent.grades) var student: ComplexIndexStudent?
    
    init() throws {
        guard let subject = Subject.allCases.randomElement(),
              let grade = Grade.allCases.randomElement(),
              let examBoard = ExamBoard.allCases.randomElement() else {
            throw ComplexIndexDataError.dataNotFound
        }
        self.id = UUID().uuidString
        self.subject = subject.rawValue
        self.grade = grade.rawValue
        self.examBoard = examBoard.rawValue
    }
    
    init(id: String = UUID().uuidString, subject: Subject, examBoard: ExamBoard, grade: Grade) {
        self.id = id
        self.subject = subject.rawValue
        self.examBoard = examBoard.rawValue
        self.grade = grade.rawValue
    }
    
    static func randomGrades() -> [ComplexIndexGrade] {
        let max = Int.random(in: 1..<7)
        return (0...max).compactMap { _ in
            try? ComplexIndexGrade()
        }
    }
}

// MARK: - Fixtures

enum ComplexIndexDataFixtures {
    static let firstNames: [String] = [
        "Liam","Noah","Oliver","Elijah","James","William","Benjamin","Lucas","Henry","Alexander",
        "Emma","Olivia","Ava","Isabella","Sophia","Charlotte","Amelia","Mia","Harper","Evelyn"
    ]
    static let surnames: [String] = [
        "Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez","Martinez",
        "Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas","Taylor","Moore","Jackson","Martin"
    ]
    static let schoolNames: [String] = [
        "Greenwood High School","Riverview Academy","Hillside Grammar","Lakeside Comprehensive",
        "Maplewood College","Cedar Grove School","Sunnydale High","Brookfield School"
    ]
    static let schoolLocations: [String] = [
        "London","Manchester","Birmingham","Leeds","Glasgow","Liverpool","Bristol","Sheffield"
    ]
}
