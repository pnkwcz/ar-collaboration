import express, { Request, Response } from "express";
import bodyParser from "body-parser";

const app = express();
const port = 3000;

app.use(bodyParser.json());

interface AnchorData {
  id: string;
  name: string;
  transform: number[][];
}

let anchors: AnchorData[] = [
  {
    transform: [
      [0.9997162, 0, 0.023823699, 0],
      [0, 0.99999994, 0, 0],
      [-0.023823688, 0, 0.9997162, 0],
      [0.13515183, -0.93535024, -1.3613191, 0.99999994],
    ],
    name: "toaster",
    id: "B5E57260-606C-494F-8FFF-62F102B93DFB",
  },
  {
    transform: [
      [0.999781, -0.0008701497, 0.020911159, 0],
      [0.00080155, 0.99999285, 0.0032886325, 0],
      [-0.02091389, -0.0032694673, 0.99977595, 0],
      [0.05356829, -0.85162914, -1.4684893, 1],
    ],
    id: "2A8257C7-4E22-4EFC-87D2-6861AA398837",
    name: "chair",
  },
  {
    id: "D2D93AAA-1DE9-429D-9BAD-20BC76E78CD2",
    transform: [
      [0.9516939, 0.000035163095, -0.30704862, 0],
      [0.000114136565, 0.9999997, 0.00046828462, 0],
      [0.3070486, -0.00048052185, 0.9516938, 0],
      [-0.41913128, -0.81732845, -1.1596085, 1],
    ],
    name: "chair",
  },
  {
    name: "toaster",
    transform: [
      [0.999715, 0, -0.023873795, 0],
      [0, 0.99999994, 0, 0],
      [0.023873797, 0, 0.999715, 0],
      [0.051218573, -0.9327265, -0.92207503, 0.99999994],
    ],
    id: "53F56D31-078A-4B43-BC18-5131D71A3A89",
  },
  {
    id: "7A89899B-C3A6-4008-8796-D625E7A0B57F",
    transform: [
      [0.9999716, 0, -0.0075282287, 0],
      [0, 0.99999994, 0, 0],
      [0.0075282347, 0, 0.99997175, 0],
      [-0.24189723, -0.93652064, -0.8170799, 0.99999994],
    ],
    name: "toaster",
  },
  {
    name: "toaster",
    transform: [
      [0.970512, 0, 0.24105285, 0],
      [0, 0.99999994, 0, 0],
      [-0.24105285, 0, 0.9705121, 0],
      [0.12092605, -0.94260633, -0.69585776, 0.99999994],
    ],
    id: "E9F24ED2-89D5-4DA5-B2F5-15C9F171038F",
  },
  {
    transform: [
      [0.9996541, 0, 0.026300786, 0],
      [0, 0.99999994, 0, 0],
      [-0.026300788, 0, 0.99965405, 0],
      [-0.19753645, -0.93326694, -0.4616815, 0.99999994],
    ],
    name: "toaster",
    id: "E7DFDEAF-EFF1-44D4-89D5-1817694EAE21",
  },
];

app.post(
  "/addAnchor",
  (req: Request<null, null, AnchorData>, res: Response) => {
    console.log(req.body);
    const { id, name, transform } = req.body;

    if (!id || !name || !transform) {
      return res.status(400).json({ error: "Invalid anchor data" });
    }

    const newAnchor = { id, name, transform };
    anchors.push(newAnchor);

    return res.status(201).json({ message: "Anchor added successfully" });
  }
);

app.get("/getAnchors", (req: Request, res: Response) => {
  console.log(anchors);

  return res.status(200).json(anchors);
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
