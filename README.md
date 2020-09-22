# PEP

[PEP](https://macpep.org/) is an acronym for PDF Editing Program (for Mac). It's a free and open source PDF editor for Mac. It is a lightweight alternative to Adobe Acrobat.

For now, PEP is work-in-progress and it's constantly updated everyday.

Currently working on the core, a PDF engine called Gene from scratch. You can build this app with Xcode, and see the simple rendering result, and if you are interested in 
the tests, just click Test in your Xcode, if should be all pass.

## What I am working on
I update the core PDF engine (called Gene) almost everyday.

## What has been done
### Things Done
* A lexer (GLexer.h|m) which turns pdf content into tokens
* A parser (GParser.h|m) which parse tokens from lexer into pdf objects (String, Name, Dictionary, Stream, etc...)
* Objects classes (GObjects.h|m) which present PDF objects

### Things unfinished
* GDocument (GDocument.h|m) which loads a PDF file, and render/edit it
* GPage (GPage.h|m) which presents a single PDF page
* GDecoders which implement all decoders for decoding stream objects
* GInterpreter (GInterpreter.h|m) which renders grapchic and text of a PDF page.

## Roadmap

I don't have any roadmap yet, but i will publish one later at the right moment. I hope someone will see the potential of PEP, and donate towards it to speed up the development process.
