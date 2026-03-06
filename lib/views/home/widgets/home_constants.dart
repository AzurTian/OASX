const kHomeTaskListCollapsedHeight = 250.0;
const kHomeTaskListExpandedHeight = 500.0;
const kHomeScriptCardChromeHeight = 95.0;

double homeScriptCardHeight(double taskListHeight) =>
    kHomeScriptCardChromeHeight + taskListHeight;
