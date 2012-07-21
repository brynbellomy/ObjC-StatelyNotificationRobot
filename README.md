# // stately notifications robot

# what

**SEStatefulNotificationsRobot** is a wrapper for `NSNotification` that simplifies
keeping track of and responding to `enum`- (or with a few typecasts, `BOOL`-)based
state changes on some observable thing.

# uh what does that mean

best explained with an example.


## long running process ...

let's say you have some long-running process -- for example, you're loading a set
of images via an HTTP request.  these images have to be available on a
`UIViewController` that you're about to push.  until they're available, you need
all of the buttons on the view to be disabled.



## ... + non-trivial observer code ...


normally, you would probably write some code in the view controller's
`-viewWillAppear:` method to check if the HTTP request has finished.  you might
set up a notification observer + handler, for example.  you would also probably
write some code to disable the buttons if the HTTP request was not done at that
point, as well as some code to enable them if they were.



## ... + lots of observers = NSNightmare

this isn't so bad, but that's only because i'm far, far too lazy to illustrate a
more complex scenario in which things start to get out of hand.

but they can, and quickly.  for instance, what if you can't even _initialize_
some of your UIView's components until some _other_ background thread completes
some task you've assigned it?  and once it's initialized, it should also be
watching that original HTTP request to determine its current state?  okay, do all
of your checking again... add more state flags... etc.

you might decide to write a huge "checker" method that goes through all of your
controls and enables them/disables them/recolorizes them/etc. any time your HTTP
request (and any of the other long-running processes your controls depend upon)
changes state.  but then you'll probably be sending a bunch of unnecessary
messages, including from time to time a bunch of messages to `nil`, especially
if your "checker" method is called from `viewDidLoad` or `viewWillAppear`.

this isn't the end of the world in terms of performance, but it can lead to messy
code for sure.

## synopsis of the preceding paragraphs

if you're in a situation where you have lots of different observers watching the
states of lots of different processes, and they should all respond to these
states in relatively complex ways that interdepend and cross-connect, but you
__STILL__ demand easily readable, easily maintainable code that resists turning
into absolute spaghetti, then you might consider __SEStatelyNotificationRobot__.




# ok fine how do you use it

there's a singleton `SEStatelyNotificationRobot` instance called `sharedRobot`
that you can use to simplify your code a bit.  think of it as a cousin to
`[NSNotificationCenter defaultCenter]`.


## registering state observers

just register your state observers like this:

```objective-c
[[SEStatelyNotificationRobot sharedRobot] handleStateOf: kMyHTTPRequest
                                              handlerID: kMyFirstButton
                                                onQueue: [NSOperationQueue mainQueue]
                                              withBlock: ^(SEState currentState, NSDictionary *stateInfo) {
                                                
                                                if (currentState == MyState_NotFinished) {
                                                  _firstButton.enabled = NO;
                                                }
                                                else if (currentState == MyState_Finished) {
                                                  _firstButton.enabled = YES;
                                                }

                                              }];

[[SEStatelyNotificationRobot sharedRobot] handleStateOf: kMyHTTPRequest
                                              handlerID: kMySecondButton
                                                onQueue: [NSOperationQueue mainQueue]
                                              withBlock: ^(SEState currentState, NSDictionary *stateInfo) {
                                                
                                                if (currentState == MyState_NotFinished) {
                                                  _secondButton.enabled = NO;
                                                }
                                                else if (currentState == MyState_Finished) {
                                                  _secondButton.enabled = YES;
                                                }

                                              }];
```

the moment you make these calls, your handler blocks will be called and handed
the current state of your 'stative thing', i.e., `kMyHTTPRequest`.  in other
words, by setting up state observers in your initialization code, your observing
objects will actually be **correctly initialized** in addition to being
registered as observers.  one less chunk of code to worry about and maintain, as
long as you write your handler blocks with this in mind.



## changing a state (and thereby triggering your observers' handler blocks)

```objective-c
[[SEStatelyNotificationRobot sharedRobot] changeStateOf: kMyHTTPRequest
                                                     to: MyState_Finished
                                              stateInfo: myStateInfoDictionary];
```

the moment you call this, your handler blocks are all called with the new state
and the `stateInfo` dictionary you passed in.

note that you can omit the `stateInfo` parameter if you don't need it.




# license (MIT)

Copyright (c) 2012 bryn austin bellomy < <bryn.bellomy@gmail.com> >

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN
AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.







