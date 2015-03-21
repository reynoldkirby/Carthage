//
//  Archive.swift
//  Carthage
//
//  Created by Justin Spahr-Summers on 2015-02-13.
//  Copyright (c) 2015 Carthage. All rights reserved.
//

import CarthageKit
import Commandant
import Foundation
import LlamaKit
import ReactiveCocoa

public struct ArchiveCommand: CommandType {
	public let verb = "archive"
	public let function = "Archives a built framework into a zip that Carthage can use"

	public func run(mode: CommandMode) -> Result<(), CommandantError> {
		return ColdSignal.fromResult(ArchiveOptions.evaluate(mode))
			.mergeMap { options -> ColdSignal<()> in
				let formatting = options.colorOptions.formatting

				return ColdSignal.fromValues(Platform.supportedPlatforms)
					.map { platform in platform.relativePath.stringByAppendingPathComponent(options.frameworkName).stringByAppendingPathExtension("framework")! }
					.filter { relativePath in NSFileManager.defaultManager().fileExistsAtPath(relativePath) }
					.on(next: { path in
						carthage.println(formatting.bullets + "Found " + formatting.path(string: path))
					})
					.reduce(initial: []) { $0 + [ $1 ] }
					.mergeMap { paths -> ColdSignal<()> in
						if paths.isEmpty {
							return .error(CarthageError.InvalidArgument(description: "Could not find any copies of \(options.frameworkName).framework. Make sure you're in the project’s root and that the framework has already been built.").error)
						}

						let outputPath = (options.outputPath.isEmpty ? "\(options.frameworkName).framework.zip" : options.outputPath)
						let outputURL = NSURL(fileURLWithPath: outputPath, isDirectory: false)!

						return zipIntoArchive(outputURL, paths).on(completed: {
							carthage.println(formatting.bullets + "Created " + formatting.path(string: outputPath))
						})
					}
			}
			.wait()
	}
}

private struct ArchiveOptions: OptionsType {
	let frameworkName: String
	let outputPath: String
	let colorOptions: ColorOptions

	static func create(outputPath: String)(colorOptions: ColorOptions)(frameworkName: String) -> ArchiveOptions {
		return self(frameworkName: frameworkName, outputPath: outputPath, colorOptions: colorOptions)
	}

	static func evaluate(m: CommandMode) -> Result<ArchiveOptions, CommandantError> {
		return create
			<*> m <| Option(key: "output", defaultValue: "", usage: "the path at which to create the zip file (or blank to infer it from the framework name)")
			<*> ColorOptions.evaluate(m)
			<*> m <| Option(usage: "the name of the built framework to archive (without any extension)")
	}
}
