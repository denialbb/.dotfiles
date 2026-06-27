import os
from kitty.fast_data_types import Screen
from kitty.tab_bar import DrawData, ExtraData, TabBarData, as_rgb
from kitty.utils import color_as_int
from kitty.boss import get_boss

def get_program_name(tab: TabBarData) -> str:
    try:
        boss = get_boss()
        tab_obj = boss.tab_for_id(tab.tab_id)
        if tab_obj is not None:
            window = tab_obj.active_window
            if window is not None and window.child is not None:
                cmdline = window.child.cmdline
                if cmdline:
                    prog = os.path.basename(cmdline[0])
                    if prog.startswith("-"):
                        prog = prog[1:]
                    return prog
    except Exception:
        pass
    return tab.title

def draw_tab(
    draw_data: DrawData,
    screen: Screen,
    tab: TabBarData,
    before: int,
    max_title_length: int,
    index: int,
    is_last: bool,
    extra_data: ExtraData,
) -> int:
    # 1. Determine colors
    default_bg = as_rgb(color_as_int(draw_data.default_bg))
    if tab.is_active:
        if tab.active_fg is not None:
            fg = as_rgb(tab.active_fg)
        else:
            fg = as_rgb(color_as_int(draw_data.active_fg))
    else:
        if tab.inactive_fg is not None:
            fg = as_rgb(tab.inactive_fg)
        else:
            fg = as_rgb(color_as_int(draw_data.inactive_fg))
            
    # Set colors
    screen.cursor.bg = default_bg
    screen.cursor.fg = fg
    
    # 2. Draw tab title (index:program name)
    title = get_program_name(tab)
    if tab.num_windows > 1:
        title += f" ({tab.num_windows})"
        
    # Pad title
    tab_text = f"  {index}:{title}  "
    
    # Check max length and truncate if necessary
    if len(tab_text) > max_title_length:
        # Leave room for "..."
        truncated = tab_text[:max_title_length - 3] + "..."
        screen.draw(truncated)
    else:
        screen.draw(tab_text)
        
    # 3. If this is the last tab, draw the name of the CWD of the active tab on the bottom right
    if is_last:
        boss = get_boss()
        # Retrieve the CWD of the currently active tab
        active_tab_obj = boss.active_tab
        cwd = ""
        if active_tab_obj is not None:
            cwd = active_tab_obj.get_cwd_of_active_window() or ""
        if not cwd:
            # Fallback to the current tab's active window CWD
            tab_obj = boss.tab_for_id(tab.tab_id)
            if tab_obj is not None:
                cwd = tab_obj.get_cwd_of_active_window() or ""
            
        if cwd:
            # We want the name of the cwd (basename)
            cwd_name = os.path.basename(cwd)
            if not cwd_name:
                cwd_name = "/"
            elif cwd == os.path.expanduser("~"):
                cwd_name = "~"
                
            right_text = f" {cwd_name} "
            # Set cursor to the right side of the screen
            right_x = screen.columns - len(right_text)
            if right_x > screen.cursor.x:
                # We move the cursor to the right side
                screen.cursor.x = right_x
                # Draw CWD in dim color
                screen.cursor.fg = as_rgb(color_as_int(draw_data.inactive_fg))
                screen.cursor.bg = default_bg
                screen.draw(right_text)
                # DO NOT restore screen.cursor.x to old_x!
                # By leaving it at the right edge, we tell kitty that the tab bar extends to the end of the screen,
                # which prevents kitty from clearing the right-aligned status text.
                
    return screen.cursor.x
