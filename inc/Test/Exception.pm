package Test::Exception; # wapper to T::E::LessClever
require Test::Exception::LessClever;
$INC{'Test/Exception.pm'} = __FILE__;
sub import {
    shift;
    Test::Exception::LessClever->export_to_level(1, @_);
}
1;
