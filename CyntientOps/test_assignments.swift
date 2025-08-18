import Foundation

print("🔍 Testing comprehensive worker assignments...")

struct TestTask {
    let building: String
    let assignedWorker: String
}

let testTasks = [
    TestTask(building: "131 Perry Street", assignedWorker: "Greg Hutson"),
    TestTask(building: "68 Perry Street", assignedWorker: "Greg Hutson"),
    TestTask(building: "135-139 West 17th Street", assignedWorker: "Kevin Dutan"),
    TestTask(building: "136 West 17th Street", assignedWorker: "Kevin Dutan"),
    TestTask(building: "138 West 17th Street", assignedWorker: "Kevin Dutan"),
    TestTask(building: "117 West 17th Street", assignedWorker: "Kevin Dutan"),
    TestTask(building: "112 West 18th Street", assignedWorker: "Kevin Dutan"),
    TestTask(building: "12 West 18th Street", assignedWorker: "Edwin Lema"),
    TestTask(building: "104 Franklin Street", assignedWorker: "Luis Lopez"),
    TestTask(building: "41 Elizabeth Street", assignedWorker: "Mercedes Inamagua"),
    TestTask(building: "36 Walker Street", assignedWorker: "Angel Guirachocha"),
    TestTask(building: "115 7th Avenue", assignedWorker: "Shawn Magloire")
]

let workerNameToId = [
    "Greg Hutson": "1",
    "Edwin Lema": "2", 
    "Kevin Dutan": "4",
    "Mercedes Inamagua": "5",
    "Luis Lopez": "6",
    "Angel Guirachocha": "7",
    "Shawn Magloire": "8"
]

let buildingMap = [
    "131 Perry Street": "10",
    "68 Perry Street": "6",
    "135-139 West 17th Street": "3",
    "136 West 17th Street": "13",
    "138 West 17th Street": "5",
    "117 West 17th Street": "9",
    "112 West 18th Street": "7",
    "12 West 18th Street": "1",
    "104 Franklin Street": "4",
    "41 Elizabeth Street": "8",
    "36 Walker Street": "18",
    "115 7th Avenue": "19"
]

var assignments: [String: [String]] = [:]
for (workerName, workerId) in workerNameToId {
    let workerTasks = testTasks.filter { $0.assignedWorker == workerName }
    let workerBuildings = Array(Set(workerTasks.map { buildingMap[$0.building] ?? "1" }))
    assignments[workerName] = workerBuildings
    print("✅ \(workerName): \(workerBuildings.count) buildings assigned - \(workerBuildings)")
}

print("")
print("📊 Total building coverage: \(Set(assignments.values.flatMap { $0 }).count) unique buildings")
print("📊 Total workers with assignments: \(assignments.count)")

