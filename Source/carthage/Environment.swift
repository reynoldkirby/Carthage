//
//  Environment.swift
//  Carthage
//
//  Created by J.D. Healy on 2/6/15.
//  Copyright (c) 2015 Carthage. All rights reserved.
//

import CarthageKit
import Foundation
import LlamaKit

internal func getEnvironmentVariable(variable: String) -> Result<String, CarthageError> {
	let environment = NSProcessInfo.processInfo().environment

	if let value = environment[variable] as? String {
		return success(value)
	} else {
		return failure(CarthageError.MissingEnvironmentVariable(variable: variable).error)
	}
}

/// Information about the possible parent terminal.
internal struct Terminal {
	/// Terminal type retrieved from `TERM` environment variable.
	static var terminalType: String? {
		return getEnvironmentVariable("TERM").value()
	}
	
	/// Whether terminal type is `dumb`.
	static var isDumb: Bool {
		return (terminalType?.caseInsensitiveCompare("dumb") == .OrderedSame) ?? false
	}
	
	/// Whether STDOUT is a TTY.
	static var isTTY: Bool {
		return isatty(STDOUT_FILENO) != 0
	}
}
