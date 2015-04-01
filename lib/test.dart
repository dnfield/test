// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

import 'package:path/path.dart' as p;

import 'src/backend/declarer.dart';
import 'src/backend/invoker.dart';
import 'src/backend/suite.dart';
import 'src/backend/test_platform.dart';
import 'src/deprecated/configuration.dart';
import 'src/deprecated/test_case.dart';
import 'src/runner/reporter/no_io_compact.dart';
import 'src/utils.dart';

export 'package:matcher/matcher.dart';

export 'src/deprecated/configuration.dart';
export 'src/deprecated/simple_configuration.dart';
export 'src/deprecated/test_case.dart';
export 'src/frontend/expect.dart';
export 'src/frontend/expect_async.dart';
export 'src/frontend/future_matchers.dart';
export 'src/frontend/prints_matcher.dart';
export 'src/frontend/test_on.dart';
export 'src/frontend/throws_matcher.dart';
export 'src/frontend/throws_matchers.dart';

/// The global declarer.
///
/// This is used if a test file is run directly, rather than through the runner.
Declarer _globalDeclarer;

/// Gets the declarer for the current scope.
///
/// When using the runner, this returns the [Zone]-scoped declarer that's set by
/// [IsolateListener] or [IframeListener]. If the test file is run directly,
/// this returns [_globalDeclarer] (and sets it up on the first call).
Declarer get _declarer {
  var declarer = Zone.current[#test.declarer];
  if (declarer != null) return declarer;
  if (_globalDeclarer != null) return _globalDeclarer;

  // Since there's no Zone-scoped declarer, the test file is being run directly.
  // In order to run the tests, we set up our own Declarer via
  // [_globalDeclarer], and schedule a microtask to run the tests once they're
  // finished being defined.
  _globalDeclarer = new Declarer();
  scheduleMicrotask(() {
    var suite =
      new Suite(_globalDeclarer.tests,
            path: p.prettyUri(Uri.base),
            platform: "VM")
      .filter(TestPlatform.vm, os: currentOSGuess);
    // TODO(nweiz): Set the exit code on the VM when issue 6943 is fixed.
    new NoIoCompactReporter([suite], color: true).run();
  });
  return _globalDeclarer;
}

// TODO(nweiz): This and other top-level functions should throw exceptions if
// they're called after the declarer has finished declaring.
/// Creates a new test case with the given description and body.
///
/// The description will be added to the descriptions of any surrounding
/// [group]s. If [testOn] is passed, it's parsed as a [platform selector][]; the
/// test will only be run on matching platforms.
///
/// [platform selector]: https://github.com/dart-lang/test/#platform-selector-syntax
void test(String description, body(), {String testOn}) =>
    _declarer.test(description, body, testOn: testOn);

/// Creates a group of tests.
///
/// A group's description is included in the descriptions of any tests or
/// sub-groups it contains. [setUp] and [tearDown] are also scoped to the
/// containing group.
///
/// If [testOn] is passed, it's parsed as a [platform selector][]; the test will
/// only be run on matching platforms.
///
/// [platform selector]: https://github.com/dart-lang/test/#platform-selector-syntax
void group(String description, void body(), {String testOn}) =>
    _declarer.group(description, body, testOn: testOn);

/// Registers a function to be run before tests.
///
/// This function will be called before each test is run. [callback] may be
/// asynchronous; if so, it must return a [Future].
///
/// If this is called within a test group, it applies only to tests in that
/// group. [callback] will be run after any set-up callbacks in parent groups or
/// at the top level.
void setUp(callback()) => _declarer.setUp(callback);

/// Registers a function to be run after tests.
///
/// This function will be called after each test is run. [callback] may be
/// asynchronous; if so, it must return a [Future].
///
/// If this is called within a test group, it applies only to tests in that
/// group. [callback] will be run before any tear-down callbacks in parent
/// groups or at the top level.
void tearDown(callback()) => _declarer.tearDown(callback);

/// Handle an error that occurs outside of any test.
void handleExternalError(error, String message, [stackTrace]) {
  // TODO(nweiz): handle this better.
  registerException(error, stackTrace);
}

/// Registers an exception that was caught for the current test.
void registerException(error, [StackTrace stackTrace]) =>
    Invoker.current.handleError(error, stackTrace);

// What follows are stubs for various top-level names supported by unittest
// 0.11.*. These are preserved for the time being for ease of migration, but
// should be removed before this is released as stable.

@deprecated
typedef dynamic TestFunction();

@deprecated
Configuration testConfiguration = new Configuration();

@deprecated
bool formatStacks = true;

@deprecated
bool filterStacks = true;

@deprecated
String groupSep = ' ';

@deprecated
void logMessage(String message) => print(message);

@deprecated
final testCases = [];

@deprecated
const int BREATH_INTERVAL = 200;

@deprecated
TestCase get currentTestCase => null;

@deprecated
const PASS = 'pass';

@deprecated
const FAIL = 'fail';

@deprecated
const ERROR = 'error';

@deprecated
void skip_test(String spec, TestFunction body) {}

@deprecated
void solo_test(String spec, TestFunction body) => test(spec, body);

@deprecated
void skip_group(String description, void body()) {}

@deprecated
void solo_group(String description, void body()) => group(description, body);

@deprecated
void filterTests(testFilter) {}

@deprecated
void runTests() {}

@deprecated
void ensureInitialized() {}

@deprecated
void setSoloTest(int id) {}

@deprecated
void enableTest(int id) {}

@deprecated
void disableTest(int id) {}

@deprecated
withTestEnvironment(callback()) => callback();