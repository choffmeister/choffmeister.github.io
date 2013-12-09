title: "Parsing command-line arguments with C#"
publishDate: "2013-09-20"
abstract: |
  In the last time I often build command-line tools with C# that
  needed some parsing of the command-line arguments passed in.
  Often I just have done simple comparison of strings to detect
  the arguments...

In the last time I often build command-line tools with C# that needed some parsing of the command-line arguments passed in. Often I just have done simple comparison of strings to detect the arguments. Since doing everything the same incomplete crap is bad, I build a simple library called DotArguments to handle that stuff. It allows defining the arguments, types etc via a simple POCO argument container class with some attributes.

The library is heavily unit tested and rock solid. It comes with a GNU compliant parser. It can be found at [DotArguments](https://github.com/choffmeister/DotArguments) and licensed under the permissive MIT license. Feel free to use it or contribute.

You can easily install the package via [NuGet](http://www.nuget.org/packages/DotArguments/).

## Example

<script src="https://gist.github.com/choffmeister/7877701.js?file=DemoArguments.cs"></script>

Here are some examples, how the application can be invoked and what values would be populated:

<script src="https://gist.github.com/choffmeister/7877701.js?file=example1"></script>
<script src="https://gist.github.com/choffmeister/7877701.js?file=example2"></script>
<script src="https://gist.github.com/choffmeister/7877701.js?file=example3"></script>

And now some invocation with invalid arguments:

<script src="https://gist.github.com/choffmeister/7877701.js?file=example4"></script>
<script src="https://gist.github.com/choffmeister/7877701.js?file=example5"></script>
