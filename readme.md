# Texturesynthesis Practical (Summer term 2015, University of Mainz)

This practical was about implementing algorithms of texture synthesis using a language of choice. We used Dart for implementing those algorithms.

## Authors
* [Jennifer Ulges](https://github.com/julges)
* [Patric Vormstein](https://github.com/pvormste)

## Based on following algorithms

* ["Texture Synthesis by Non-parametric Sampling"](https://www.eecs.berkeley.edu/Research/Projects/CS/vision/papers/efros-iccv99.pdf) by Alexei A. Efros and Thomas K. Leung
* ["Fast Texture Synthesis using Tree-structured Vector Quantization"](https://graphics.stanford.edu/papers/texture-synthesis-sig00/texture.pdf) by Li-Yi Wei and Marc Levoy
* ["Texture Optimization for Example-based Synthesis"](http://physbam.stanford.edu/~kwatra//publications/TO/TO-final.pdf) by Vivek Kwatra, Irfan Essa, Aaron Bobick and Nipun Kwatra

## Examples

### Non parametric sampling (patch size 10x10 px)

| Input image   | Output (single resolution) | Output (multi resolution)  |
| ------------- |---------------| ------|
| <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/web/images/simple.jpg">      | <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/examples/nonparametric/single/simple_10x10.png"> | <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/examples/nonparametric/multi/simple_10x10.png"> |
| <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/web/images/wall.png">      | <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/examples/nonparametric/single/wall-10x10.png">      |   <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/examples/nonparametric/multi/wall_10x10.png"> |
| <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/web/images/metal_small.png"> | <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/examples/nonparametric/single/metal_10x10.png">      |    <img src="https://raw.githubusercontent.com/pvormste/ts-practical/master/examples/nonparametric/multi/metal_10x10.png"> |

## License

### MIT-License

Copyright (c) 2015 Jennifer Ulges, Patric Vormstein

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