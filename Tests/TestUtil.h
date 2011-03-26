//
//  TestUtil.h
//  IQWidgets for iOS
//
//  Copyright 2011 EvolvIQ
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

@class SenTestCase;

extern NSDate* __D(SenTestCase* self, NSString* str);
extern void __NEED_UI();

#define D(x) __D(self, x)

#define NEED_UI __NEED_UI();