/*
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import LoggerAPI
import SwiftKuery
import SwiftKueryPostgreSQL
import SwiftKuerySQLite

#if os(Linux)
    import Glibc
#else
    import Darwin
#endif


let db = ProcessInfo.processInfo.environment["DB"] ?? "postgres"
let dbHost = ProcessInfo.processInfo.environment["DB_HOST"] ?? "localhost"
let dbPort = Int32(ProcessInfo.processInfo.environment["DB_PORT"] ?? "5432") ?? 5432
let dbName = "hello_world"
let dbUser = "benchmarkdbuser"
let dbPass = "benchmarkdbpass"

let dbRows = 10000
let maxValue = 10000

class World: Table {
    let tableName = "World"
    
    let id = Column("id")
    let randomNumber = Column("randomNumber")
}

let world = World()

let selectQuery = Select(world.randomNumber, from: world)
     .where(world.id == Parameter())
let updateQuery = Update(world, set: [(world.randomNumber, Parameter())])
    .where(world.id == Parameter())


let dbConnPoolOpts = ConnectionPoolOptions(initialCapacity: 20, maxCapacity: 50, timeout:10000)
let dbConnPool = PostgreSQLConnection.createPool(host: dbHost, port: dbPort, options: [.databaseName(dbName), .userName(dbUser), .password(dbPass)], poolOptions: dbConnPoolOpts)

let select = prepare(selectQuery)!
let update = prepare(updateQuery)!

func prepare(_ query: Query) -> PreparedStatement? {
    guard let dbConn = dbConnPool.getConnection() else {
        print("Failed to get connection")
        return nil
    }
    do {
        let stmt = try dbConn.prepareStatement(query)
        return stmt
    }
    catch {
        print(error)
        return nil
    }
}

func releaseConnection(connection: Connection) {
    connection.closeConnection()
}

// Return a random number within the range of rows in the database
func randomNumberGenerator(_ maxVal: Int) -> Int {
    #if os(Linux)
        return Int(random() % maxVal) + 1
    #else
        return Int(arc4random_uniform(UInt32(maxVal))) + 1
    #endif
}

// Get a random row (range 1 to 10,000) from DB: id(int),randomNumber(int)
// Convert to object using object-relational mapping (ORM) tool
// Serialize object to JSON - example: {"id":3217,"randomNumber":2149}
func getRandomRow() -> ([String:Int]?, AppError?) {
    var resultDict: [String:Int]? = nil
    var errRes: AppError? = nil
    // Get a dedicated connection object for this transaction from the pool
    guard let dbConn = dbConnPool.getConnection() else {
        errRes = AppError.OtherError("Timed out waiting for a DB connection from the pool")
        print("No connection")
        return (resultDict, errRes)
    }

    let rnd = randomNumberGenerator(dbRows)

    dbConn.execute(preparedStatement: select, parameters: [rnd]) { result in
        guard result.success else {
            errRes = AppError.DBKueryError("Query failed - status \(String(describing: result.asError))")
            print("Query failed - status \(String(describing: result.asError))")
            return
        }
        if let resultSet = result.asResultSet {
            for row in resultSet.rows {
                for value in row {
                    if let unwrapped = value {
                        guard let randomNumber = unwrapped as? Int32 else {
                        errRes = AppError.DBKueryError("Error: could not get field as an Int")
                        return
                    }
                        resultDict = ["id":rnd, "randomNumber":Int(randomNumber)]
                    } else {
                        errRes = AppError.DBKueryError("Error: randomNumber value is nil")
                    }
                }
            }
        }
    }
    return (resultDict, errRes)
}

// Updates a row of World to a new value.
func updateRow(id: Int) throws  -> AppError? {
   // Get a dedicated connection object for this transaction from the pool
    guard let dbConn = dbConnPool.getConnection() else {
        throw AppError.OtherError("Timed out waiting for a DB connection from the pool")
    }
    let rndValue = randomNumberGenerator(maxValue)
    var errRes: AppError? = nil
    dbConn.execute(preparedStatement: update, parameters: [rndValue, id]) { result in
        guard result.success else {
            errRes = AppError.DBKueryError("Query failed - status \(String(describing: result.asError))")
    	    print("Query failed - status \(String(describing: result.asError))")
            return
        }
    }
    return errRes
}

