## Tracking Satellites on Google Earth

Tracking satellites using TLEs and Perl (KML/Google Earth output). This single Perl file is designed to sit on your server and by default returns a KML file tracking the International Space Station over the next 2 hours. The default TLW source file is at http://celestrak.com/NORAD/elements/visual.txt.

### File useage

With a few simple arguments the file can slightly alter the returned output in KML. Defaults shown in brackets.

- _url:_ URL of TLW data file (http://celestrak.com/NORAD/elements/visual.txt)
- _id:_ Comma-sperated list of TLE ids from the file (25544)
- _hor_ Boolean Y or N to show satellite's horizon (Y)
- _path_ Integer number of hours to shown future path of satellite (2)
- _ex_ Boolean Y or N to show line connecting satellite to ground (N)
- _icon_ URL path to icon for the satellite in Google Earth (http://resources.orbitingfrog.com/<<ID>>.png)

### Perl Packages Required

CGI, Math, POSIX, LWP and Astro::Coord

It was written in Perl because it utilises the _Astro-satpass_ package by Tom Wyant (found at http://search.cpan.org/dist/Astro-satpass/). Perl is not my favorutie package but this is a speedy library that does most of the grunt work. Big thank you to Tom for all his hard work. :)