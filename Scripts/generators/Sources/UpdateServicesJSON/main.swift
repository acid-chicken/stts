import Foundation

// Run via Scripts/update_services_json.sh. To add a provider: create
// Generators/<Provider>Generator.swift conforming to ServiceGenerator and list it below.

func repoRoot() -> String {
    if let srcRoot = ProcessInfo.processInfo.environment["SRCROOT"] {
        return srcRoot
    }

    // #filePath is fixed at compile time, so this works regardless of the caller's cwd.
    // main.swift is 5 components below the repo root.
    var path = URL(fileURLWithPath: #filePath)
    for _ in 0..<5 {
        path.deleteLastPathComponent()
    }
    return path.path
}

let generators: [ServiceGenerator] = [
    AzureGenerator(),
    AzureDevOpsGenerator(),
    FirebaseGenerator(),
    SalesforceGenerator(),
    AdobeGenerator(),
    AppleGenerator(),
    AppleDeveloperGenerator(),
    GoogleCloudPlatformGenerator(),
    AWSRegionsGenerator(),
    AWSServicesGenerator()
]

let servicesPath = "\(repoRoot())/Resources/services.json"
await ServicesJSONUpdater(servicesPath: servicesPath).run(generators: generators)
