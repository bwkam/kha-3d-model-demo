import kha.graphics4.ConstantLocation;
import kha.math.FastMatrix4;
import kha.graphics4.CompareMode;
import kha.Shaders;
import kha.Assets;
import kha.Image;
import kha.graphics4.TextureUnit;
import kha.graphics4.Graphics;
import kha.graphics4.PipelineState;
import kha.graphics4.Usage;
import kha.graphics4.VertexData;
import kha.graphics4.VertexStructure;
import kha.graphics4.IndexBuffer;
import kha.graphics4.VertexBuffer;
import kha.math.FastVector2;
import kha.math.FastVector3;

typedef Vertex = {
	var position:FastVector3;
	var normal:FastVector3;
	var texCoords:FastVector2;
}

typedef Texture = {
	var id:Int;
	var type:String;
	var tex:Image;
	var path:String;
}

typedef Light = {
	var position:FastVector3;
	var direction:FastVector3;

	var constant:Float;
	var linear:Float;
	var quadratic:Float;
	var ambient:FastVector3;
	var diffuse:FastVector3;
	var specular:FastVector3;
	var shininess:Float;
	var cutOff:Float;
	var outerCutOff:Float;
}

class Mesh {
	public var vertices:Array<Vertex>;
	public var indices:Array<Int>;
	public var textures:Array<Texture>;

	private var vertexBuffer:VertexBuffer;
	private var indexBuffer:IndexBuffer;
	private var structure:VertexStructure;
	private var pipeline:PipelineState;

	private var projID:ConstantLocation;
	private var modelID:ConstantLocation;
	private var viewID:ConstantLocation;

	private var lightPositionID:ConstantLocation;
	private var lightDirectionID:ConstantLocation;
	private var lightConstantID:ConstantLocation;
	private var lightLinearID:ConstantLocation;
	private var lightQuadraticID:ConstantLocation;
	private var lightAmbientID:ConstantLocation;
	private var lightDiffuseID:ConstantLocation;
	private var lightSpecularID:ConstantLocation;
	private var shininessID:ConstantLocation;
	private var cutOffID:ConstantLocation;
	private var outerCutOffID:ConstantLocation;

	public function new(vertices:Array<Vertex>, indices:Array<Int>, textures:Array<Texture>) {
		this.vertices = vertices;
		this.indices = indices;
		this.textures = textures;

		setUpMesh();
	}

	public function setUpMesh() {
		var structureLength = 8;
		structure = new VertexStructure();

		structure.add("aPos", VertexData.Float3);
		structure.add("aNormal", VertexData.Float3);
		structure.add("aTexCoords", VertexData.Float2);

		// vertex buffer

		vertexBuffer = new VertexBuffer(vertices.length, structure, Usage.StaticUsage);

		var vbData = vertexBuffer.lock();

		for (i => vertex in vertices) {
			// vertices
			vbData.set(i * structureLength + 0, vertex.position.x);
			vbData.set(i * structureLength + 1, vertex.position.y);
			vbData.set(i * structureLength + 2, vertex.position.z);

			// normals
			vbData.set(i * structureLength + 3, vertex.normal.x);
			vbData.set(i * structureLength + 4, vertex.normal.y);
			vbData.set(i * structureLength + 5, vertex.normal.z);

			// texture uvs
			vbData.set(i * structureLength + 6, vertex.texCoords.x);
			vbData.set(i * structureLength + 7, vertex.texCoords.y);
		}
		vertexBuffer.unlock();
		// index buffer

		indexBuffer = new IndexBuffer(indices.length, Usage.StaticUsage);

		var iData = indexBuffer.lock();

		for (i in 0...iData.length) {
			iData.set(i, indices[i]);
		}

		indexBuffer.unlock();

		pipeline = new PipelineState();
		pipeline.inputLayout = [structure];
		pipeline.vertexShader = Shaders.model_vert;
		pipeline.fragmentShader = Shaders.model_frag;
		pipeline.depthWrite = true;
		pipeline.depthMode = CompareMode.Less;
		pipeline.colorAttachmentCount = 1;
		pipeline.colorAttachments[0] = kha.graphics4.TextureFormat.RGBA32;
		pipeline.depthStencilAttachment = kha.graphics4.DepthStencilFormat.Depth16;
		pipeline.compile();

		projID = pipeline.getConstantLocation("proj");
		modelID = pipeline.getConstantLocation("model");
		viewID = pipeline.getConstantLocation("view");

		lightPositionID = pipeline.getConstantLocation("pointLight.position");
		lightDirectionID = pipeline.getConstantLocation("pointLight.direction");
		lightConstantID = pipeline.getConstantLocation("pointLight.constant");
		lightLinearID = pipeline.getConstantLocation("pointLight.linear");
		lightQuadraticID = pipeline.getConstantLocation("pointLight.quadratic");
		lightAmbientID = pipeline.getConstantLocation("pointLight.ambient");
		lightDiffuseID = pipeline.getConstantLocation("pointLight.diffuse");
		lightSpecularID = pipeline.getConstantLocation("pointLight.specular");
		shininessID = pipeline.getConstantLocation("material.shininess");
		cutOffID = pipeline.getConstantLocation("pointLight.cutOff");
		outerCutOffID = pipeline.getConstantLocation("pointLight.outerCutOff");
	}

	public function draw(g:Graphics, proj:FastMatrix4, model:FastMatrix4, view:FastMatrix4, light:Light) {
		g.setPipeline(pipeline);

		g.setVertexBuffer(vertexBuffer);
		g.setIndexBuffer(indexBuffer);

		g.setMatrix(projID, proj);
		g.setMatrix(modelID, model);
		g.setMatrix(viewID, view);

		g.setFloat3(lightPositionID, light.position.x, light.position.y, light.position.z);
		g.setFloat3(lightDirectionID, light.direction.x, light.direction.y, light.direction.z);

		g.setFloat(lightConstantID, light.constant);
		g.setFloat(lightLinearID, light.linear);
		g.setFloat(lightQuadraticID, light.quadratic);
		g.setFloat(shininessID, light.shininess);

		g.setFloat(cutOffID, light.cutOff);
		g.setFloat(outerCutOffID, light.outerCutOff);

		g.setFloat3(lightAmbientID, light.ambient.x, light.ambient.y, light.ambient.z);
		g.setFloat3(lightDiffuseID, light.diffuse.x, light.diffuse.y, light.diffuse.z);
		g.setFloat3(lightSpecularID, light.specular.x, light.specular.y, light.specular.z);

		var diffuseNr = 1;
		var specularNr = 1;

		for (i in 0...textures.length) {
			var number:String = "";
			var name:String;
			var texID:TextureUnit;

			name = textures[i].type;

			if (name == "texture_diffuse")
				number = Std.string(diffuseNr++);
			else if (name == "texture_specular")
				number = Std.string(specularNr++);

			texID = pipeline.getTextureUnit("material." + name + number);

			g.setTexture(texID, textures[i].tex);
			g.setTextureParameters(texID, kha.graphics4.TextureAddressing.Clamp, kha.graphics4.TextureAddressing.Clamp,
				kha.graphics4.TextureFilter.LinearFilter, kha.graphics4.TextureFilter.LinearFilter, kha.graphics4.MipMapFilter.NoMipFilter);
		}
		g.drawIndexedVertices();
	}
}
