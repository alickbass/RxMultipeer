# An abstraction over multipeer connectivity that can be tested

Using the adapter design pattern, we can test multipeer code with heavy mocking.

## Example code

### Testing

```
let session = MockSession()
let current = CurrentClient(session: session)

let othersession = MockSession()
let other = CurrentClient(othersession)

current.rx_string >- subscribeNext { |s| in
  println(s)
}

other.rx_data >- subscribeNext { |d| in
  prinln(NSString(data: d, encoding: UIInt))
  current.sendData(NSData(string: "there"), mode: Reliable)
}

other.sendData(NSData(string: "hello"), mode: .Reliable)
```

### @TODO : Usage

## License

The MIT License (MIT)

Copyright (c) 2015 Nathan Kot

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
