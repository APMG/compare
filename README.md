Compare
=======

Simple site crawler and comparison tool with diff output.


Instructions
------------

Enter two URLs to spider and compare.

The second site will be spidered and compared to the same URL on the first site.

The spider will stay within the domain.

Example:

	ruby compare.rb http://mpr.org http://stage.mpr.org

Exceptions can be added with additional arguments. Example:

	ruby compare.rb http://mpr.org http://stage.mpr.org test1 test2

The previous example would spider `http://minnesota.publicradio.org/hello.shtml` but would skip `http://minnesota.publicradio.org/test1.shtml`

Credits
-------

Andrew Stevenson wrote the original version of this spider/compare utility based on a very simple [Gist](https://gist.github.com/will-in-wi/9f167d21877d6a5b8bd7) by William Johnston

William Johnston then expanded it for further use.