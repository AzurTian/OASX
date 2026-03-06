const kHomeTaskListCollapsedHeight = 150.0;
const kHomeTaskListExpandedHeight = 400.0;
const kHomeScriptCardChromeHeight = 93.0;

double homeScriptCardHeight(double taskListHeight) =>
    kHomeScriptCardChromeHeight + taskListHeight;
