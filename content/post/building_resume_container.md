---
title: "Building a Latex resume and not worrying about compiling it"
date: 2018-02-03T20:26:18+01:00
draft: false
---

A long time ago I came accross Adrian Friggeri's resume built with Latex. I couldn't find the original template, but did found [this page](https://www.latextemplates.com/template/friggeri-resume-cv) with a customization.

I found that template amazing and I decided I wanted my resume to be like that. I was looking for a new job, so why not?  That being said, I spent hours and hours on it; I installed uncountable dependencies, made some Helvetica fonts work on my Linux box, created the perfect descriptions for my previous positions, adjusted the alignments with so much care. Phew, I finally managed to have my fancy curriculum!

Eventually I got a new job and forgot about it, until I decided to update it. At that point I had a clean OS installation, so I'd have to install all those dependencies again. As a result, I decided to ditch that resume and build a simpler one, based on the well-known [moderncv](https://www.ctan.org/pkg/moderncv) template. This one was simpler to compile as it required fewer dependencies so I thought my problem was soved.

However, recently I decided to update it, and guess what? For some reason it didn't compile. Then I realized that the building process of my resume would be a great candidate to be containerized. To make things better, I found out that there is a `moderncv` package available in Fedora 27. So I quickly put together this simple Dockerfile in my resume directory:

```
FROM fedora-minimal:27

VOLUME /data

WORKDIR /data

RUN microdnf update && \
    microdnf install texlive texlive-xetex texlive-moderncv && \
    microdnf clean all
```

Voilà! Build the image, push it to Docker Hub and you will never have install `texlive` and its dependencies only to compile your resume again.

If you are interested you can check my [GitHub repository](https://github.com/bertinatto/resume) for a complete example.

