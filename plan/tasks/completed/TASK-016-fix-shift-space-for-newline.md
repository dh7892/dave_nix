We have some helper (danix-add, danix-ask etc) that pop up a zellij floating pane and start a Pi session in there with some initial prompt. I've noticed that in those windows shift-space doesn't work to insert a newline, instead it submits the current prompt.

This is different than the usual behaviour in a normal pane/PI session.

Please invetigate and fix this issue so that shift-space works as expected in the floating panes created by our helper functions.
