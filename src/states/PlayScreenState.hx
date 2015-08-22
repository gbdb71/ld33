
package states;

import luxe.Color;
import luxe.Scene;
import luxe.Sprite;
import luxe.States;
import luxe.Input;
import luxe.tween.Actuate;
import luxe.Vector;

import luxe.Visual;
import phoenix.Texture.FilterType;

import luxe.importers.tiled.TiledMap;
import luxe.importers.tiled.TiledObjectGroup;

// ------------------

import luxe.physics.nape.DebugDraw;

import nape.phys.Body;
import nape.phys.BodyType;
import nape.geom.Vec2;
import nape.phys.Material;
import nape.shape.Polygon;

import luxe.components.physics.nape.*;
import nape.callbacks.*;
import nape.constraint.PivotJoint;

using Lambda;

class PlayScreenState extends State {
    static public var StateId :String = 'PlayScreenState';
    var scene :Scene;

    //The level tiles
    var map: TiledMap;
    var map_scale: Int = 1;

    var drawer : DebugDraw;

    //for attaching to the mouse when dragging
    var mouseJoint : PivotJoint;

    var ballCollisionType :CbType = new CbType();
    var obstacleCollisionType :CbType = new CbType();

    var obstacles :Array<NapeBody>;

    public function new() {
        super({ name: StateId });
        scene = new Scene('PlayScreenScene');
    }

    override function init() {
        //Fetch the loaded tmx data from the assets
        var map_data = Luxe.resources.text('assets/test.tmx').asset.text;

        //parse that data into a usable TiledMap instance
        map = new TiledMap({ format:'tmx', tiled_file_data: map_data });

        //Create the tilemap visuals
        // map.display({ scale:map_scale, filter:FilterType.nearest });

        reset_world();
    }

    function reset_world() {
        if (drawer != null) {
            drawer.destroy();
            drawer = null;
        }

        //create the drawer, and assign it to the nape debug drawer
        drawer = new DebugDraw();
        Luxe.physics.nape.debugdraw = drawer;

        var w = Luxe.screen.w;
        var h = Luxe.screen.h;

        mouseJoint = new PivotJoint(Luxe.physics.nape.space.world, null, Vec2.weak(), Vec2.weak());
        mouseJoint.space = Luxe.physics.nape.space;
        mouseJoint.active = false;
        mouseJoint.stiff = false;

        var border = new Body(BodyType.STATIC);
        border.shapes.add(new Polygon(Polygon.rect(0, 0, w, -1)));
        border.shapes.add(new Polygon(Polygon.rect(0, h, w, 1)));
        border.shapes.add(new Polygon(Polygon.rect(0, 0, -1, h)));
        border.shapes.add(new Polygon(Polygon.rect(w, 0, 1, h)));
        border.space = Luxe.physics.nape.space;

        drawer.add(border);

        var margin_x = (Luxe.screen.width - map.total_width) / 2 + 32;
        new Sprite({
            pos: Luxe.screen.mid.clone(),
            size: new Vector(map.total_width, map.total_height),
            color: new Color(0, 0.5, 0.8)
        });

        var ball_size = 16;
        var ball = new Sprite({
            name: 'ball',
            size: new Vector(16, 16),
            texture: Luxe.resources.texture('assets/ball.png')
        });
        var rubber = Material.rubber();
        rubber.elasticity = 8;
        var ball_col = new CircleCollider({
            body_type:BodyType.DYNAMIC,
            material: rubber,
            x: 100,
            y: 100,
            r: ball_size / 2
        });
        ball.add(ball_col);
        ball_col.body.cbTypes.add(ballCollisionType);

        obstacles = [];

        for (group in map.tiledmap_data.object_groups) {
            for (object in group.objects) {
                if (group.name == 'boxes') {

                    var image_source = ['box.png', 'circle.png']; // horrible hack
                    var obstacle = new Sprite({
                        pos: new Vector(margin_x + object.pos.x, object.pos.y),
                        size: new Vector(object.width, object.height),
                        rotation_z: object.rotation,
                        texture: Luxe.resources.texture('assets/' + image_source[object.gid-1])
                    });
                    trace('Rotation ${object.rotation}');

                    var obstacle_col = new BoxCollider({
                        body_type: BodyType.STATIC,
                        material: Material.steel(),
                        x: margin_x + object.pos.x,
                        y: object.pos.y,
                        w: object.width,
                        h: object.height,
                        rotation: object.rotation
                    });
                    obstacle.add(obstacle_col);
                    obstacle_col.body.cbTypes.add(obstacleCollisionType);

                    obstacles.push(obstacle_col);
                }
            }
        }

        var interactionListener = new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, ballCollisionType, obstacleCollisionType, hitBox);
        Luxe.physics.nape.space.listeners.add(interactionListener);
    }

    function hitBox(collision :InteractionCallback) :Void {
        // collision.
        // trace('ballToWall');
        var ballBody :nape.phys.Body = collision.int1.castBody;
        var obstacleBody :nape.phys.Body = collision.int2.castBody;

        var obstacle = obstacles.find(function(ob) {
            return ob.body == obstacleBody;
        });
        obstacles.remove(obstacle);

        var position = new Vector((ballBody.position.x + obstacleBody.position.x) / 2, (ballBody.position.y + obstacleBody.position.y) / 2);

        Luxe.events.fire('hit', { entity: obstacle.entity, body: obstacle.body, position: position });
        if (obstacles.empty()) Luxe.events.fire('won');
        
        var hitVisual = new Visual({
            pos: position,
            color: new Color(1, 1, 1, 0.4),
            geometry: Luxe.draw.circle({ r: 25 }),
            scale: new Vector(0.5, 0.5),
            depth: 10
        });
        Actuate.tween(hitVisual.scale, 0.3, { x: 1, y: 1 }).onComplete(function() {
            hitVisual.destroy();
        });

        drawer.remove(obstacleBody);
        obstacleBody.space = null;
        obstacle.entity.destroy();
    }

    override function onenter<T>(_value :T) {
        trace('ENTER $StateId');
    }

    override function onleave<T>(_value :T) {
        trace('LEAVE $StateId');
    }

    override function onkeyup(e :KeyEvent) {
        switch (e.keycode) {
            case Key.key_r:
                Luxe.scene.empty();
                Luxe.physics.nape.space.clear();
                reset_world();
            case Key.key_g: Luxe.physics.nape.draw = !Luxe.physics.nape.draw;
        }
    }

    override function onmouseup( e:MouseEvent ) {
        mouseJoint.active = false;
    }

    override function onmousedown( e:MouseEvent ) {
        var mousePoint = Vec2.get(e.pos.x, e.pos.y);

        for (body in Luxe.physics.nape.space.bodiesUnderPoint(mousePoint)) {
            if (!body.isDynamic()) {
                continue;
            }

            mouseJoint.anchor1.setxy(e.pos.x, e.pos.y);

            // Configure hand joint to drag this body.
            //   We initialise the anchor point on this body so that
            //   constraint is satisfied.
            //
            //   The second argument of worldPointToLocal means we get back
            //   a 'weak' Vec2 which will be automatically sent back to object
            //   pool when setting the mouseJoint's anchor2 property.
            mouseJoint.body2 = body;
            mouseJoint.anchor2.set( body.worldPointToLocal(mousePoint, true));

            // Enable hand joint!
            mouseJoint.active = true;
            break;
        }

        mousePoint.dispose();
    } //onmousedown

    override function onmousemove( e:MouseEvent ) {
        if (mouseJoint.active) {
            mouseJoint.anchor1.setxy(e.pos.x, e.pos.y);
        }
    }

    #if mobile
        override function ontouchmove( e:TouchEvent ) {
            if (mouseJoint.active) {
                mouseJoint.anchor1.setxy(e.pos.x, e.pos.y);
            }
        } //ontouchmove
    #end //mobile
}