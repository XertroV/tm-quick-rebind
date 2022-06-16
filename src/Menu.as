namespace Menu {
    // const string MAIN_COLOR = "\\$4af";  // blue
    // const string MAIN_COLOR = "\\$92f";  // purple
    const string MAIN_COLOR = "\\$5f4";  // green
    const string L_GRAY = "\\$aaa";
    const vec4 L_GRAY_VEC = vec4(2,2,2,1) / vec4(3,3,3,1);

    int selectedPadIx = -1;
    bool _enabled = false;

    UI::Font@ sectionLabel = UI::LoadFont("fonts/Lato-MediumItalic.ttf", 16, -1, -1, true, true);
    UI::Font@ normalFont = UI::LoadFont("fonts/Lato-Regular.ttf", 16, -1, -1, true, true);

    string grp(const string &in s) {
        return "\\$<" + s + "\\$>";
    }

    string mainColor(const string &in s) {
        return grp(MAIN_COLOR + s);
    }

    const string GetIcon(CInputScriptPad@ pad = null) {
        PadType ty = pad !is null ? FromEPadType(pad.Type) : Setting_PadType;
        if (ty == PadType::Keyboard)
            return Icons::KeyboardO;
        if (ty == PadType::Mouse)
            return Icons::Kenney::MouseAlt;
        return Icons::Kenney::GamepadAlt;
    }
    string CurrIcon = GetIcon();

    /********/

    void RenderPluginMenuItem() {
        if (UI::MenuItem(mainColor(CurrIcon) + " Quick Rebind", "", Setting_Enabled)) {
            Setting_Enabled = !Setting_Enabled;
        }
    }

    /********/

    void RenderMenuMain() {
        _enabled = IsUiDialogSafe();
        if (!Setting_Enabled) return;
        // UI::PushFont(normalFont);
        UI::PushStyleColor(UI::Col::TextDisabled, L_GRAY_VEC);
        bool menuOpen = UI::BeginMenu(mainColor(CurrIcon) + " Bindings", _enabled);
        if (UI::IsItemHovered()) {
            // true if the disabled menubar menuitem is hovered.
            AddSimpleTooltip("\\$f62" + "Sorry, it's unsafe to bind keys right now.");
        }
        if (menuOpen) {
            int tfs = 0
                // | UI::TableFlags::SizingStretchSame
                // | UI::TableFlags::SizingFixedFit
                ;
            if (UI::BeginTable("bindings-menu-table", 2, tfs)) {
                UI::TableSetupColumn("l", UI::TableColumnFlags::WidthFixed, 300);
                UI::TableSetupColumn("r", UI::TableColumnFlags::WidthFixed, 300);

                UI::TableNextRow();

                UI::TableNextColumn();
                // MenuMinWidth();
                MenuLabelSep("Selected Input", true);
                ListInputDevices();
                MenuLabelSep("Device", true);
                ListDeviceSettings();
                MenuLabelSep("Player Bindings", true);
                ListPlayerBindings();

                UI::TableNextColumn();
                // MenuMinWidth();
                MenuLabelSep("Other Bindings", true);
                ListOtherBindings();

                UI::EndTable();
            }

            UI::EndMenu();
        } else {
            string newi = GetIcon(GetCurrPad());
            if (newi != CurrIcon)
                CurrIcon = newi;
        }

        UI::PopStyleColor(1);
        // UI::PopFont();
    }

    /********/

    void MenuLabelSep(const string &in l, bool padAbove = false) {
        if (padAbove) UI::Dummy(vec2(0, 0));
        UI::PushFont(sectionLabel);
        UI::TextDisabled("  " + l + "  ");
        UI::Separator();
        UI::PopFont();
    }

    void MenuMinWidth() {
        vec2 initPos = UI::GetCursorPos();
        UI::Dummy(vec2(150, 1));  // setting min width basically
        UI::SetCursorPos(initPos);
    }

    void ListInputDevices() {
        auto pads = GetPads();

        // reset if a controller is removed
        if (selectedPadIx >= int(pads.Length))
            selectedPadIx = -1;

        for (uint i = 0; i < pads.Length; i++) {
            auto pad = pads[i];

            // default to keyboard
            if (selectedPadIx < 0 && FromEPadType(pad.Type) == Setting_PadType) {
                OnSelectedPad(i);
            }
            string padName = GetIcon(pad) + " " + pad.ModelName;
            if (MenuItemNoClose(padName, '', int(i) == selectedPadIx)) {
                OnSelectedPad(i);
            }
        }
    }

    void OnSelectedPad(int ix) {
        selectedPadIx = ix;
        auto pad = GetPad(ix);
        GI::GetManiaPlanetScriptApi().InputBindings_UpdateList(CGameManiaPlanetScriptAPI::EInputsListFilter::All, pad);
        Setting_PadType = FromEPadType(pad.Type);
    }

    CInputScriptPad@ GetPad(uint i) {
        auto pads = GetPads();
        if (i > pads.Length)
            return null;
        return pads[i];
    }

    CInputScriptPad@ GetCurrPad() {
        return GetPad(selectedPadIx);
    }

    MwFastBuffer<CInputScriptPad@> GetPads() {
        return GI::GetInputPort().Script_Pads;
    }

    void ListDeviceSettings() {
        if (UI::MenuItem("Unbind one button", "Ctrl+U", false, _enabled)) {
            GI::UnbindInput(GetPad(selectedPadIx));
        }
    }

    uint GetPlayerInputsCount() {
        return GI::GetManiaPlanetScriptApi().InputBindings_PlayerInputsCount;
    }

    void ListPlayerBindings() {
        ListBindingsFrom(0, GetPlayerInputsCount());
    }

    void ListOtherBindings() {
        ListBindingsFrom(GetPlayerInputsCount(), 0xffff);
    }

    void ListBindingsFrom(uint start, uint length) {
        auto mspa = GI::GetManiaPlanetScriptApi();
        auto bindings = mspa.InputBindings_Bindings;
        auto actions = mspa.InputBindings_ActionNames;
        for (uint i = start; i < Math::Min(start + length, bindings.Length); i++) {
            if (UI::MenuItem(actions[i], bindings[i], false, _enabled)) {
                debugPrint("Clicked: " + actions[i]);
                GI::BindInput(i, GetCurrPad());
            }
        }
    }
}
