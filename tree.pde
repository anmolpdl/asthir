/*
 * tree.pde
 *
 * Created : 03/06/2019
 *  Author : n-is
 *   email : 073bex422.nischal@pcampus.edu.np
 */

Branch base;

public void renderTree(float x, float y, float z) {
        pushMatrix();
        translate(x, y, z);
        base.render();
        popMatrix();
}

public void setupTree() {
        base = new Branch();
}

public class Branch {
        float xRot;
        float yRot;
        float zRot;
        Branch parent;
        int depth;

        Branch child1;
        Branch child2;

        float change = .85f;
        private static final float max_depth_ = 10;

        public Branch(Branch parent) {
                this.parent = parent;
                this.depth = parent.depth + 1;
                xRot = random(-1, 1) * change;
                yRot = random(-1, 1) * change;
                zRot = random(-1, 1) * change;
                makeChildren();
        }

        public Branch() {
                depth = 0;
                xRot = 0;
                yRot = 0;
                zRot = 0;
                makeChildren();
        }

        public void makeChildren() {
                if( depth < max_depth_ ) {
                        if( Math.random() > .2 ) {
                                child1 = new Branch( this );
                        }
                        if( Math.random() > .2 ) {
                                child2 = new Branch( this );
                        }
                }
        }

        public void render() {
                fill( 255 - (depth*25), 128 + (depth*6), 0 );
                pushMatrix();

                rotateX( xRot );
                rotateY( yRot );
                rotateZ( zRot );

                translate( 0, 0, (20-depth)*.5f );
                box( (20-depth)*.1f, (20-depth)*.1f, (20-depth) );
                translate( 0, 0, (20-depth)*.5f );

                if( child1 != null ) child1.render();
                if( child2 != null ) child2.render();
                popMatrix();
        }
}
