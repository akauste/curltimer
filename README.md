# CurlTimer

This is small app for saving timer data to SQLite table and providing web ui
to view the latest speed(s).

Backend is written in Perl (Mojo::Lite). Frontend uses React.

## How to run

Using port 8889:

morbo -l http://localhost:8888 curltimer.pl

## How to build

cd timer
npm run build --prod