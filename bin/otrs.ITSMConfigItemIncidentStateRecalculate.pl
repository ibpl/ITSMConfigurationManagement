#!/usr/bin/perl
# --
# bin/otrs.ITSMConfigItemIncidentStateRecalculate.pl - to recalculate the incident states of config items
# Copyright (C) 2001-2014 OTRS AG, http://otrs.com/
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

# use ../ as lib location
use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use Getopt::Long;
use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Main;
use Kernel::System::Time;
use Kernel::System::DB;
use Kernel::System::ITSMConfigItem;
use Kernel::System::GeneralCatalog;

# common objects
my %CommonObject = ();
$CommonObject{ConfigObject} = Kernel::Config->new();
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'OTRS-ITSMConfigItemIncidentStateRecalculate.pl',
    %CommonObject,
);
$CommonObject{MainObject}           = Kernel::System::Main->new(%CommonObject);
$CommonObject{TimeObject}           = Kernel::System::Time->new(%CommonObject);
$CommonObject{DBObject}             = Kernel::System::DB->new(%CommonObject);
$CommonObject{ConfigItemObject}     = Kernel::System::ITSMConfigItem->new(%CommonObject);
$CommonObject{GeneralCatalogObject} = Kernel::System::GeneralCatalog->new(%CommonObject);

print "\n";
print "otrs.ITSMConfigItemIncidentStateRecalculate.pl\n";
print "Recalculates the incident state of config items.\n";
print "This is necessary after changing the sysconfig option 'ITSM::Core::IncidentLinkTypeDirection'.\n";
print "Copyright (C) 2001-2014 OTRS AG, http://otrs.com/\n\n";

my $Help;

GetOptions(
    'help' => \$Help,
);

# show usage
if ( $Help ) {
    print "Usage: $0 [options] \n";
    print "  Options are as follows:\n";
    print "  --help  display this option help\n\n";
    exit 1;
}

# get class list
my $ClassList = $CommonObject{GeneralCatalogObject}->ItemList(
    Class => 'ITSM::ConfigItem::Class',
);

# get the valid class ids
my @ValidClassIDs = sort keys %{ $ClassList };

# get all config items ids form all valid classes
my $ConfigItemsIDsRef = $CommonObject{ConfigItemObject}->ConfigItemSearch(
    ClassIDs     => \@ValidClassIDs,
);

# get number of config items
my $CICount = scalar @{ $ConfigItemsIDsRef };

print "Recalculating incident state for $CICount config items.\n";

my $Count = 0;
CONFIGITEM:
for my $ConfigItemID ( @{ $ConfigItemsIDsRef } ) {

    my $Success = $CommonObject{ConfigItemObject}->CurInciStateRecalc(
        ConfigItemID => $ConfigItemID,
    );

    if (!$Success) {
        print "... could not recalculate incident state for config item id '$ConfigItemID'!\n";
        next CONFIGITEM;
    }

    $Count++;

    if ($Count % 100 == 0) {
        print "... $Count config items recalculated.\n";
    }
}

print "\nReady. Recalculated $Count config items.\n\n";

1;

