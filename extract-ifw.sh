#!/bin/bash
# QT-CI Project
# License: Apache-2.0
# https://github.com/benlau/qtci

set -e #quit on error

if [ $# -lt 2 ];
then
    echo extract-ifw qtifw output_path
    exit -1
fi

INSTALLER=$1
OUTPUT=$2
SCRIPT="$(mktemp)"

cat <<EOF > $SCRIPT
function Controller() {
    installer.autoRejectMessageBoxes;
}

Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}


Controller.prototype.TargetDirectoryPageCallback = function() {
    var widget = gui.currentPageWidget();

    if (widget != null) {
        widget.TargetDirectoryLineEdit.setText("$OUTPUT");
    }

    gui.clickButton(buttons.NextButton);

}

Controller.prototype.LicenseAgreementPageCallback = function() {
    var widget = gui.currentPageWidget();

    if (widget != null) {
        widget.AcceptLicenseRadioButton.setChecked(true);
    }

    gui.clickButton(buttons.NextButton);

}

Controller.prototype.ReadyForInstallationPageCallback = function() {

    gui.clickButton(buttons.CommitButton);
}

Controller.prototype.FinishedPageCallback = function() {

    gui.clickButton(buttons.FinishButton);
}
EOF

chmod u+x $INSTALLER
QT_QPA_PLATFORM=minimal $INSTALLER --script $SCRIPT