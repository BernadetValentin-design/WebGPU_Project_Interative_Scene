# WebGPU Scene Editor

> **Note:** Replace this image with a screenshot or GIF of your running application!
![App Preview](screenshot2.png)

### [**Launch Live Demo**](https://your-username.github.io/your-repo-name/)

A high-performance interactive 3D scene editor built from scratch using **WebGPU** and **WGSL** raymarching. Create, manipulate, and blend geometric primitives in real-time right in your browser.

## Features

*   **WebGPU Raymarching**: Utilizes the latest graphics API for smooth, high-fidelity rendering.
*   **Interactive Scene Editor**:
    *   **Add/Remove Objects**: Dynamically add Spheres, Boxes, and Tori to the scene.
    *   **Real-time Properties**: Adjust Position (XYZ), Dimensions, and Color using intuitive sliders.
*   **Camera Controls**:
    *   **Orbit**: Click and drag to rotate the camera around the scene.
    *   **Move**: Use **ZQSD** (or WASD) keys to fly through the infinite grid.
    *   **Zoom**: Use the **Mouse Wheel** to move closer or further away.
*   **Smooth Blending**: Objects automatically merge with smooth unions when placed close together.

## Tech Stack

*   **WebGPU** & **WGSL**: Core rendering engine and shaders.
*   **JavaScript (Vanilla)**: State management and UI interaction.
*   **HTML5 & CSS3**: Modern, responsive interface layout.

## Local Development

Follow these steps to run the project locally:

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
    cd YOUR_REPO_NAME
    ```

2.  **Start a local server**:
    WebGPU requires a secure context or `localhost`. You can use Python's built-in HTTP server:
    ```bash
    # Python 3
    python -m http.server 8000
    ```

3.  **Run the App**:
    Open your browser (Chrome/Edge/Firefox Nightly) and navigate to:
    `http://localhost:8000`


