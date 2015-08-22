
package states;

import luxe.Color;
import luxe.Input.KeyEvent;
import luxe.Input.Key;
import luxe.Scene;
import luxe.States;
import luxe.Text;
import luxe.tween.Actuate;
import luxe.Vector;
import luxe.Visual;

class TitleScreenState extends State {
    static public var StateId :String = 'TitleScreenState';

    var scene :Scene;
    var titleText :Text;
    var background :Visual;

    public function new() {
        super({ name: StateId });
        scene = new Scene('TitleScreenScene');
    }

    override function init() {
        trace('INIT $StateId');
    }

    override function onenter<T>(_value :T) {
        trace('ENTER $StateId');

        background = new Visual({
            pos: new Vector(0, Luxe.screen.h),
            size: Luxe.screen.size.clone(),
            color: new ColorHSV(0, 1, 0.2),
            scene: scene
        });

        titleText = new Text({
            pos: Luxe.screen.mid.clone(),
            text: 'This is $StateId.\n\nPress Enter',
            color: new Color(1, 1, 1, 0),
            align: TextAlign.center,
            align_vertical: TextAlign.center,
            scene: scene,
            parent: background
        });

        Actuate
            .tween(background.pos, 0.3, { y: 0 })
            .onComplete(function() {
                Actuate.tween(titleText.color, 0.3, { a: 1 });
            });
    }

    override function onleave<T>(_value :T) {
        trace('LEAVE $StateId');
        Actuate
            .tween(background.pos, 0.3, { y: -Luxe.screen.h })
            .onComplete(function() {
                scene.empty();
            });
    }

    override function onkeyup(e :KeyEvent) {
        switch (e.keycode) {
            case Key.enter: Main.switch_to_state(MenuScreenState.StateId);
            case Key.escape: Luxe.shutdown();
        }
    }
}