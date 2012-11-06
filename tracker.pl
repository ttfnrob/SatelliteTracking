#!/usr/bin/perl
print "Content-Type: application/vnd.google-earth.kml+xml\n\n";

use constant PI    => 4 * atan2(1, 1);
use CGI qw/:standard/;           # load standard CGI routines
use CGI::Carp qw(fatalsToBrowser);
use Math::Trig;
use POSIX;
use Astro::Coord::ECI::TLE;
use LWP::Simple;
use Error qw(:try);

$query = new CGI;

$idvalues = $query->param('id');
$urlvalue = $query->param('url');
$hor = $query->param('hor');
$path = $query->param('path');
$extrude = $query->param('ex');
$icon_path= $query->param('icon');


if (!$idvalues) {
	$idvalues = "25544";
}

if (!$urlvalue) {
	$urlvalue = "http://celestrak.com/NORAD/elements/visual.txt";
}

if (!$hor) {
	$hor = "Y";
}

if (!$path) {
	$path = 2;
}

if ($path eq "N") {
	$path = 0;
}

if (!$extrude) {
	$extrude = 1;
}

if ($extrude eq 'Y') {
	$extrude = 1;
}

if ($extrude eq 'N') {
	$extrude = 0;
}

#truncate path to 24hrs at most
if ($path > 24) {
	$path = 24;
}

my @idvalues = split(',', $idvalues);
my @color_array = ('BBFFBB','FFBBBB','BBBBFF');

print "
<Document>
<Style id='PolyStyle'>
<LineStyle>
<width>0</width>
</LineStyle>
<PolyStyle>
<tessellate>0</tessellate>
<altitudeMode>relativetoGround</altitudeMode>
<colorMode>normal</colorMode>
<fill>1</fill>
<outline>1</outline>
</PolyStyle>
</Style>
";

$content = get($urlvalue);
my @sats = Astro::Coord::ECI::TLE->parse ($content);
$satcount = 0;

foreach my $tle (@sats) {

	if ($satcount > 50) {

		#give message that server is overloaded
		print "<Placemark>
		<name>Too Many Objects Listed</name>
		</Placemark>
		";

		} else {

			if ( ((grep $_ eq $tle->get('id'), @idvalues) || ($idvalues eq 'ALL' )) ) {

				$this_id = $tle->get('id');
				
				if (!$icon_path) {
					$filepath = "../resources.orbitingfrog.com/$this_id.png";
					if(-e $filepath){
					 $this_icon_path = "http://resources.orbitingfrog.com/$this_id.png";
					} else {
					 $this_icon_path = "http://resources.orbitingfrog.com/25544.png";
					};
				} else {
					$this_icon_path = $icon_path;
				};
				
				$satcount = $satcount + 1;

				my $now = time();
				my $timestep = 120;
				my $iterations = 30*$path;
				$kml1 = "";
				$kml2 = "";
				$kmlr = "";
				$col = $color_array[$satcount-1];

				$satname = $tle->get('name');
				$satname =~ s/\///g;
				$satname =~ s/\&//g;

				#do error checking for this TLE set
				try {
					@latlon = $tle->universal ($now)->geodetic();
					return;
				}	
				catch Error with {
					my $ex = $tle->get('model_error');   # Get hold of the exception object
					if ($ex == 4) {
						print "<Placemark><name>Error with this TLE data.</name></Placemark>";
					}
					$error = 'TRUE';
				}
				finally {
					"";
					};  # <-- Remember the semicolon

					if ($error eq 'TRUE') {
						#do nothing
						} else {

							#loop through tracing out path of satellite
							#       for ($it = 0; $it < $iterations; ++$it) {
								$time = $now + ($it*$timestep);
								@latlon = $tle->universal ($time)->geodetic ();

								$coords[$it][0] = $latlon[0]*180/PI;
								$coords[$it][1] = $latlon[1]*180/PI;
								$coords[$it][2] = $latlon[2]*1000;

							}

							$t = 0;
							foreach $point (@coords) {
								$kml1 = $kml1.$coords[$t][1].",".$coords[$t][0].",".$coords[$t][2]."
								";
								$t++;
							}

							#find location of satellite now
							@latlon = $tle->universal ($now)->geodetic ();
							my @xyz = $tle->eci ();

							#now compute horizon distance for satellite
							$alt = $latlon[2]*1000.0; #height of sat in metres
							$horizon = 3.86*sqrt($alt);

							if ($horizon > 40041470) {
								$horizon = 40041470;
							}

							#lat long coordinates in radians
							$lat = $latlon[0];
							$long = $latlon[1];

							$d_rad = $horizon*1000.0/6378000;

							if ($hor eq "Y") {
								#loop through the array and write path linestrings
								for($i=0; $i<=360; ++$i) {
									$radial = deg2rad($i);
									$lat_rad = asin(sin($lat)*cos($d_rad) + cos($lat)*sin($d_rad)*cos($radial));
									$dlon_rad = atan2(sin($radial)*sin($d_rad)*cos($lat),cos($d_rad)-sin($lat)*sin($lat_rad));

									$lon_rad = $long + $dlon_rad;

									if ($long < 0) {
										$lon_rad2 = $long + $dlon_rad + (2*PI);
										} elsif ($long >= 0) {
											$lon_rad2 = $long + $dlon_rad - (2*PI);
										}

										if ($lon_rad < -&PI) {
											$lon_rad = -&PI;
											} elsif ($lon_rad > PI) {
												$lon_rad = PI;
											}

											if ($lon_rad2 < -&PI) {
												$lon_rad2 = -&PI;
												} elsif ($lon_rad2 > PI) {
													$lon_rad2 = PI;
												}

												$kmlr = $kmlr.rad2deg($lon_rad).",".rad2deg($lat_rad).",0 \n";
												$kmlr2 = $kmlr2.rad2deg($lon_rad2).",".rad2deg($lat_rad).",0 \n";

											}

										}

										$desc = "Current altitude: ".(sprintf("%.2f", $latlon[2]))." km<br>";

										print "
										<Folder>
										<name>".$satname."</name>
										<Style id='iss_style'>
											<IconStyle>
											<scale>1.2</scale>
											<Icon>
											<href>".$this_icon_path."</href>
											</Icon>
											</IconStyle>     
										</Style>
										<LookAt>
											<longitude>".$latlon[1]*180/PI."</longitude>
											<latitude>".$latlon[0]*180/PI."</latitude>
											<altitude>".($latlon[2]*1000.0)."</altitude>
											<range>3000000</range>
											<tilt>45</tilt>
										 </LookAt>
										 <Placemark>
											 <Style>
											 <BalloonStyle>
												<bgColor>7fffffff</bgColor>
												<text><![CDATA[
												<strong>".$satname."</strong>
												<br/><br/>
												".$desc."
												]]></text>
											 </BalloonStyle>
											 </Style>
											 <name>".$satname."</name>
											 <description><![CDATA[
											 ".$desc."
											 ]]></description>
											 <styleUrl>#iss_style</styleUrl>
											 <LookAt>
												<longitude>".$latlon[1]*180/PI."</longitude>
												<latitude>".$latlon[0]*180/PI."</latitude>
												<altitude>".($latlon[2]*1000.0)."</altitude>
												<range>3000000</range>
												<tilt>45</tilt>  
											</LookAt>
											<Point>
												<extrude>".$extrude."</extrude>
												<altitudeMode>relativeToGround</altitudeMode>
												<coordinates>".$latlon[1]*180/PI.",".$latlon[0]*180/PI.",".($latlon[2]*1000.0)."</coordinates>  
											</Point>
										</Placemark>
										";

										#if path is to be drawn, draw it
										print "<Placemark>
										<name>".$path." Hour Flight Path</name>
										<Style>
										<LineStyle>
										<color>cc".$col."</color>
										<width>2</width>
										</LineStyle>
										</Style>
										<LineString>
										<tessellate>1</tessellate>
										<altitudeMode>relativeToGround</altitudeMode>
										<coordinates>".$kml1."</coordinates>
										</LineString>
										</Placemark>
										";

										#if horixon is to be drawn, draw it now
										if ($hor eq "Y") {
											print "<Placemark>
											<Style id='PolyStyle'>
											<LineStyle>
											<color>88".$col."</color>
											</LineStyle>
											<PolyStyle>
											<color>88".$col."</color>
											</PolyStyle>
											</Style>
											<name>".$plot." Horizon</name>
											<styleUrl>#PolyStyle</styleUrl>
											<Polygon>
											<outerBoundaryIs>
											<LinearRing>
											<coordinates>".$kmlr."</coordinates>
											</LinearRing>
											</outerBoundaryIs>
											</Polygon>
											</Placemark>
											<Placemark>
											<name>".$plot." Horizon</name>
											<styleUrl>#PolyStyle</styleUrl>
											<Polygon>
											<outerBoundaryIs>
											<LinearRing>
											<coordinates>".$kmlr2."</coordinates>
											</LinearRing>
											</outerBoundaryIs>
											</Polygon>
											</Placemark>
											";
										}

										#write ending tag
										print "</Folder>";

			#}
		} else { #check sat id
			# do nothing
		}
	}#end check limit of sources
} # end for each sat loop

print '
</Document>';
